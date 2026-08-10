import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../../core/widgets/animated_background.dart';
import '../../models/sensor_reading_model.dart';
import '../../models/station_model.dart';
import '../../providers/station_provider.dart';
import '../../providers/readings_provider.dart';
import '../../providers/alerts_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final stationsAsync = ref.watch(stationsProvider);
  final selectedId    = ref.watch(selectedStationIdProvider);
  final selectedAsync = ref.watch(selectedStationProvider);
  final readingAsync  = ref.watch(latestReadingProvider);
  final alertCount    = ref.watch(alertCountProvider);
  final isDark        = Theme.of(context).brightness == Brightness.dark;

  ref.watch(autoSelectProvider);

  final reading  = readingAsync.value;
  final station  = selectedAsync.value;
  final aqiLevel = _computeAqi(reading, station);

  // ✅ Write AQI level globally so ALL screens use it
  Future.microtask(() =>
      ref.read(globalAqiLevelProvider.notifier).state = aqiLevel);

  return AnimatedBackground(
    aqiLevel: aqiLevel,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: stationsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stations) {
            if (stations.isEmpty) {
              return _EmptyState(
                  onAdd: () => context.push('/settings/devices'));
            }
            return _DashboardBody(
              stations:   stations,
              selectedId: selectedId,
              station:    station,
              reading:    reading,
              aqiLevel:   aqiLevel,
              alertCount: alertCount,
              isDark:     isDark,
              ref:        ref,
            );
          },
        ),
      ),
    ),
  );
}

  AirQualityLevel _computeAqi(
    SensorReadingModel? reading,
    StationModel? station,
  ) {
    if (reading == null || station == null) {
      return AirQualityLevel.offline;
    }
    AirQualityLevel worst = AirQualityLevel.good;
    for (final sensor in SensorConstants.sensors) {
      if (!sensor.isActive) continue;
      final value = reading.getValue(sensor.key);
      final elevated =
          station.thresholds['${sensor.key}_elevated'] ??
          sensor.defaultElevated;
      final critical =
          station.thresholds['${sensor.key}_critical'] ??
          sensor.defaultCritical;
      final level = AirQualityHelper.getLevel(value, elevated, critical);
      if (level.index > worst.index) worst = level;
    }
    return worst;
  }
}

// ── Dashboard body ────────────────────────────────────────────────────
class _DashboardBody extends ConsumerWidget {
  final List<StationModel> stations;
  final String? selectedId;
  final StationModel? station;
  final SensorReadingModel? reading;
  final AirQualityLevel aqiLevel;
  final int alertCount;
  final bool isDark;
  final WidgetRef ref;

  const _DashboardBody({
    required this.stations,
    required this.selectedId,
    required this.station,
    required this.reading,
    required this.aqiLevel,
    required this.alertCount,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            stations: stations,
            selectedId: selectedId,
            station: station,
            isDark: isDark,
            ref: ref,
          ),
        ),
        SliverToBoxAdapter(
          child: _AgiCard(
            aqiLevel: aqiLevel,
            station: station,
            reading: reading,
            alertCount: alertCount,
            isDark: isDark,
          ),
        ),
        ..._buildSensorGroups(context),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  List<Widget> _buildSensorGroups(BuildContext context) {
    final groups = SensorConstants.categories;
    return groups.expand((category) {
      final sensors = SensorConstants.byCategory(category);
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              category.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                letterSpacing: 0.12,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _SensorCard(
                sensor: sensors[i],
                reading: reading,
                station: station,
                isDark: isDark,
              ),
              childCount: sensors.length,
            ),
          ),
        ),
      ];
    }).toList();
  }
}

// ── Header ────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final List<StationModel> stations;
  final String? selectedId;
  final StationModel? station;
  final bool isDark;
  final WidgetRef ref;

  const _Header({
    required this.stations,
    required this.selectedId,
    required this.station,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Air Guard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showStationPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: station?.isOnline == true
                          ? AppColors.good
                          : AppColors.offline,
                    ),
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      station?.name ?? 'Select station',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: subColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStationPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2535) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select Station',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 12),
            ...stations.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.isOnline ? AppColors.good : AppColors.offline,
                  ),
                ),
                title: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                subtitle: Text(
                  s.location,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                trailing: s.id == selectedId
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.good,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  ref.read(selectedStationIdProvider.notifier).state = s.id;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AGI card with Lottie character ────────────────────────────────────
class _AgiCard extends StatelessWidget {
  final AirQualityLevel aqiLevel;
  final StationModel? station;
  final SensorReadingModel? reading;
  final int alertCount;
  final bool isDark;

  const _AgiCard({
    required this.aqiLevel,
    required this.station,
    required this.reading,
    required this.alertCount,
    required this.isDark,
  });

  // ── Lottie asset per level ──────────────────────────
  String? get _lottiePath {
    switch (aqiLevel) {
      case AirQualityLevel.good:
        return 'lib/assets/animations/aqi_good.json';
      case AirQualityLevel.moderate:
        return 'lib/assets/animations/aqi_moderate.json';
      case AirQualityLevel.warning:
        return 'lib/assets/animations/aqi_warning.json';
      case AirQualityLevel.critical:
        return 'lib/assets/animations/aqi_critical.json';
      case AirQualityLevel.offline:
        return null; // no animation when offline
    }
  }

  // ── Plain English label ─────────────────────────────
  String get _plainLabel {
    switch (aqiLevel) {
      case AirQualityLevel.good:
        return 'Air is Clean 😊';
      case AirQualityLevel.moderate:
        return 'Acceptable Air 😐';
      case AirQualityLevel.warning:
        return 'Unhealthy Air 😷';
      case AirQualityLevel.critical:
        return 'Hazardous Air ☠️';
      case AirQualityLevel.offline:
        return 'No Data Available';
    }
  }

  // ── User advice ─────────────────────────────────────
  String get _advice {
    switch (aqiLevel) {
      case AirQualityLevel.good:
        return 'Safe for everyone. Enjoy outdoor activities!';
      case AirQualityLevel.moderate:
        return 'Sensitive groups should limit outdoor time.';
      case AirQualityLevel.warning:
        return 'Wear a mask outside. Reduce exertion.';
      case AirQualityLevel.critical:
        return 'Stay indoors. Use air filtration immediately.';
      case AirQualityLevel.offline:
        return 'Check device connection.';
    }
  }

  int get _agiScore {
    if (reading == null) return 0;
    switch (aqiLevel) {
      case AirQualityLevel.good:
        return 42;
      case AirQualityLevel.moderate:
        return 72;
      case AirQualityLevel.warning:
        return 125;
      case AirQualityLevel.critical:
        return 175;
      case AirQualityLevel.offline:
        return 0;
    }
  }

  double get _progressValue {
    return (_agiScore / 200).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = AirQualityHelper.getColor(aqiLevel, dark: isDark);
    final bgColor = AirQualityHelper.getBgColor(aqiLevel, dark: isDark);
    final label = AirQualityHelper.getLabel(aqiLevel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: label + status pill ──────────
            Row(
              children: [
                Text(
                  'AIR GUARD INDEX',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Main row: score left, character right ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: score + progress + advice
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plain English headline
                      Text(
                        _plainLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Big score
                      _AnimatedAgiScore(score: _agiScore, color: color),

                      Text(
                        'out of 200',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _progressValue),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          builder: (_, value, __) => LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? AppColors.darkCardBorder
                                : Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Good',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.good,
                            ),
                          ),
                          Text(
                            'Hazardous',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColors.critical,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Advice box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _advice,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right: Lottie character
                Expanded(
                  flex: 4,
                  child: _lottiePath != null
                      ? Lottie.asset(
                          _lottiePath!,
                          height: 140,
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        )
                      : // Offline — static icon instead
                        SizedBox(
                          height: 140,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off,
                                size: 48,
                                color: AppColors.offline,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.offline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── AQI scale legend ───────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAFE LIMITS GUIDE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ScaleChip(
                        label: 'Good',
                        range: '0–50',
                        color: AppColors.good,
                        bgColor: AppColors.goodBg,
                        isActive: aqiLevel == AirQualityLevel.good,
                      ),
                      const SizedBox(width: 4),
                      _ScaleChip(
                        label: 'Moderate',
                        range: '51–100',
                        color: AppColors.moderate,
                        bgColor: AppColors.moderateBg,
                        isActive: aqiLevel == AirQualityLevel.moderate,
                      ),
                      const SizedBox(width: 4),
                      _ScaleChip(
                        label: 'Warning',
                        range: '101–150',
                        color: AppColors.warning,
                        bgColor: AppColors.warningBg,
                        isActive: aqiLevel == AirQualityLevel.warning,
                      ),
                      const SizedBox(width: 4),
                      _ScaleChip(
                        label: 'Critical',
                        range: '151+',
                        color: AppColors.critical,
                        bgColor: AppColors.criticalBg,
                        isActive: aqiLevel == AirQualityLevel.critical,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Alert badge ────────────────────────────
            if (alertCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.criticalBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.critical.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.critical,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$alertCount ACTIVE ALERT${alertCount > 1 ? 'S' : ''} — TAP ALERTS TAB',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── AQI scale chip ────────────────────────────────────────────────────
class _ScaleChip extends StatelessWidget {
  final String label;
  final String range;
  final Color color;
  final Color bgColor;
  final bool isActive;

  const _ScaleChip({
    required this.label,
    required this.range,
    required this.color,
    required this.bgColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? bgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              range,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isActive ? color : color.withValues(alpha: 0.5),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                color: isActive ? color : color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated AGI score counter ────────────────────────────────────────
class _AnimatedAgiScore extends StatefulWidget {
  final int score;
  final Color color;
  const _AnimatedAgiScore({required this.score, required this.color});

  @override
  State<_AnimatedAgiScore> createState() => _AnimatedAgiScoreState();
}

class _AnimatedAgiScoreState extends State<_AnimatedAgiScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedAgiScore old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = IntTween(
        begin: old.score,
        end: widget.score,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        widget.score == 0 ? '--' : '${_anim.value}',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: widget.color,
          fontFamily: 'monospace',
          height: 1.1,
        ),
      ),
    );
  }
}

// ── Sensor card ───────────────────────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final SensorInfo sensor;
  final SensorReadingModel? reading;
  final StationModel? station;
  final bool isDark;

  const _SensorCard({
    required this.sensor,
    required this.reading,
    required this.station,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final value = reading?.getValue(sensor.key);
    final elevated =
        station?.thresholds['${sensor.key}_elevated'] ?? sensor.defaultElevated;
    final critical =
        station?.thresholds['${sensor.key}_critical'] ?? sensor.defaultCritical;

    final level = sensor.isActive && value != null
        ? AirQualityHelper.getLevel(value, elevated, critical)
        : AirQualityLevel.offline;

    final color = AirQualityHelper.getColor(level, dark: isDark);
    final bgColor = isDark
        ? AppColors.darkCard
        : Colors.white.withValues(alpha: 0.60);
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : Colors.white.withValues(alpha: 0.9);

    return GestureDetector(
      onTap: sensor.isActive
          ? () => context.push('/monitor/${sensor.key}')
          : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: fullname big, sensorCode small ─
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.fullName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sensor.sensorCode,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                sensor.isActive
                    ? Icon(
                        level == AirQualityLevel.good
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: color,
                      )
                    : Icon(
                        Icons.remove,
                        size: 14,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Value ──────────────────────────────────
            sensor.isActive
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value != null
                              ? value.toStringAsFixed(1)
                              : '...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(
                          text: ' ${sensor.unit}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    '--',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                      fontFamily: 'monospace',
                    ),
                  ),

            const SizedBox(height: 3),

            // ── Worst 24h ──────────────────────────────
            if (sensor.isActive && value != null)
              Consumer(
                builder: (context, ref, _) {
                  final stationId = ref.watch(selectedStationIdProvider) ?? '';
                  final worst24h = ref.watch(worst24hProvider(stationId)).value;
                  final worstVal = worst24h?[sensor.key];
                  return Text(
                    worstVal != null
                        ? 'Worst (24h): ${worstVal.toStringAsFixed(1)}'
                        : '',
                    style: TextStyle(
                      fontSize: 8,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  );
                },
              )
            else
              Text(
                sensor.isActive ? 'Awaiting data...' : 'Not installed',
                style: TextStyle(
                  fontSize: 8,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),

            const Spacer(),

            // ── Sparkline ──────────────────────────────
            sensor.isActive
                ? _Sparkline(sensorKey: sensor.key, color: color)
                : Container(
                    height: 20,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted)
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

            const SizedBox(height: 4),

            // ── Status label ───────────────────────────
            Text(
              sensor.isActive
                  ? AirQualityHelper.getLabel(level).toUpperCase()
                  : 'NOT INSTALLED',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: sensor.isActive
                    ? color
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                letterSpacing: 0.06,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sparkline ─────────────────────────────────────────────────────────
class _Sparkline extends ConsumerWidget {
  final String sensorKey;
  final Color color;
  const _Sparkline({required this.sensorKey, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? [];
    final points = history.map((r) => r.getValue(sensorKey)).toList();

    if (points.length < 2) {
      return SizedBox(
        height: 20,
        child: Center(
          child: Container(height: 1, color: color.withValues(alpha: 0.3)),
        ),
      );
    }

    return SizedBox(
      height: 20,
      child: CustomPaint(
        painter: _SparklinePainter(points: points, color: color),
        size: const Size(double.infinity, 20),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = ((i - 1) / (points.length - 1)) * size.width;
        final prevY =
            size.height - ((points[i - 1] - min) / range) * size.height;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color;
}

// ── Empty state ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_off,
              size: 64,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
            const SizedBox(height: 16),
            Text(
              'No stations added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first Air Guard device\nto start monitoring.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Device',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
