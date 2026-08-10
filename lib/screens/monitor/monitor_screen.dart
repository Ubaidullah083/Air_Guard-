import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../../core/widgets/animated_background.dart';
import '../../providers/readings_provider.dart';
import '../../providers/station_provider.dart';
import '../../models/sensor_reading_model.dart';

class MonitorScreen extends ConsumerWidget {
  final String sensorKey;
  const MonitorScreen({super.key, required this.sensorKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiLevel = ref.watch(globalAqiLevelProvider);
    final sensor = SensorConstants.byKey(sensorKey);
    if (sensor == null) {
      return const Scaffold(body: Center(child: Text('Sensor not found')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationAsync = ref.watch(selectedStationProvider);
    final readingAsync = ref.watch(latestReadingProvider);
    final historyAsync = ref.watch(historyProvider);
    final station = stationAsync.value;
    final reading = readingAsync.value;
    final history = historyAsync.value ?? [];

    final value = reading?.getValue(sensorKey) ?? 0;
    final elevated =
        station?.thresholds['${sensorKey}_elevated'] ?? sensor.defaultElevated;
    final critical =
        station?.thresholds['${sensorKey}_critical'] ?? sensor.defaultCritical;
    final level = sensor.isActive
        ? AirQualityHelper.getLevel(value, elevated, critical)
        : AirQualityLevel.offline;
    final color = AirQualityHelper.getColor(level, dark: isDark);

    // Stats
    final values = history.map((r) => r.getValue(sensorKey)).toList();
    final minVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final avgVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;

    // Trend
    String trend = '→ Stable';
    if (values.length >= 4) {
      final recent = values.sublist(values.length - 4);
      final older = values.sublist(
        values.length - 8 < 0 ? 0 : values.length - 8,
        values.length - 4,
      );
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.isEmpty
          ? recentAvg
          : older.reduce((a, b) => a + b) / older.length;
      if (recentAvg > olderAvg * 1.05) {
        trend = '↑ Rising';
      } else if (recentAvg < olderAvg * 0.95) {
        trend = '↓ Falling';
      }
    }

    return AnimatedBackground(
      aqiLevel: aqiLevel,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _MonitorHeader(sensor: sensor, station: station, isDark: isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _ValueDisplay(
                        sensor: sensor,
                        value: value,
                        level: level,
                        color: color,
                        trend: trend,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _TimeFilter(),
                      const SizedBox(height: 14),
                      _ChartCard(
                        history: history,
                        sensorKey: sensorKey,
                        color: color,
                        elevated: elevated,
                        critical: critical,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _StatsRow(
                        minVal: minVal,
                        maxVal: maxVal,
                        avgVal: avgVal,
                        unit: sensor.unit,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ThresholdNote(
                        elevated: elevated,
                        critical: critical,
                        unit: sensor.unit,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────
class _MonitorHeader extends StatelessWidget {
  final SensorInfo sensor;
  final dynamic station;
  final bool isDark;

  const _MonitorHeader({
    required this.sensor,
    required this.station,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 14, color: textColor),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'CHEMICAL ANALYSIS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: subColor,
                    letterSpacing: 0.1,
                  ),
                ),
                Text(
                  '${sensor.sensorCode} ${sensor.fullName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ── Big value display ─────────────────────────────────────────────────
class _ValueDisplay extends StatelessWidget {
  final SensorInfo sensor;
  final double value;
  final AirQualityLevel level;
  final Color color;
  final String trend;
  final bool isDark;

  const _ValueDisplay({
    required this.sensor,
    required this.value,
    required this.level,
    required this.color,
    required this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              sensor.isActive ? value.toStringAsFixed(1) : '--',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              sensor.unit,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                AirQualityHelper.getLabel(level).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: isDark ? AppColors.darkCardBorder : AppColors.lightMuted,
              ),
              const SizedBox(width: 8),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Time filter ───────────────────────────────────────────────────────
class _TimeFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(timeFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['1H', '24H', '7D'].map((f) {
        final isSelected = f == selected;
        return GestureDetector(
          onTap: () => ref.read(timeFilterProvider.notifier).state = f,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.good
                  : (isDark
                        ? AppColors.darkCard
                        : Colors.white.withValues(alpha: 0.65)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.good
                    : (isDark
                          ? AppColors.darkCardBorder
                          : Colors.white.withValues(alpha: 0.9)),
              ),
            ),
            child: Text(
              f,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final List<SensorReadingModel> history;
  final String sensorKey;
  final Color color;
  final double elevated;
  final double critical;
  final bool isDark;

  const _ChartCard({
    required this.history,
    required this.sensorKey,
    required this.color,
    required this.elevated,
    required this.critical,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.getValue(sensorKey));
    }).toList();

    final values = history.map((r) => r.getValue(sensorKey)).toList();
    final minY = values.isEmpty
        ? 0.0
        : (values.reduce((a, b) => a < b ? a : b) * 0.9);
    final maxY = values.isEmpty
        ? 10.0
        : (values.reduce((a, b) => a > b ? a : b) * 1.1);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: spots.length < 2
          ? Center(
              child: Text(
                'Collecting data...',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
            )
          : LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color:
                        (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightMuted)
                            .withValues(alpha: 0.4),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                // Warn threshold line
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: elevated,
                      color: AppColors.moderate.withValues(alpha: 0.6),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.moderate,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) => 'Warn',
                      ),
                    ),
                    HorizontalLine(
                      y: critical,
                      color: AppColors.critical.withValues(alpha: 0.6),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.critical,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) => 'Critical',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: spots.length <= 15,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 1.5,
                        strokeColor: color,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            s.y.toStringAsFixed(2),
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final double minVal, maxVal, avgVal;
  final String unit;
  final bool isDark;

  const _StatsRow({
    required this.minVal,
    required this.maxVal,
    required this.avgVal,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(label: 'MIN', value: minVal, unit: unit, isDark: isDark),
        const SizedBox(width: 8),
        _StatBox(label: 'AVG', value: avgVal, unit: unit, isDark: isDark),
        const SizedBox(width: 8),
        _StatBox(label: 'MAX', value: maxVal, unit: unit, isDark: isDark),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                letterSpacing: 0.08,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Threshold note ────────────────────────────────────────────────────
class _ThresholdNote extends StatelessWidget {
  final double elevated, critical;
  final String unit;
  final bool isDark;

  const _ThresholdNote({
    required this.elevated,
    required this.critical,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'WARNS AT ${elevated.toStringAsFixed(0)} $unit  ·  '
      'CRITICAL AT ${critical.toStringAsFixed(0)} $unit',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        letterSpacing: 0.08,
      ),
    );
  }
}
