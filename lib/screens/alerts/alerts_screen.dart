import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../models/alert_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/station_provider.dart';
import '../../services/firebase_service.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertsAsync = ref.watch(allAlertsProvider);
    final filtered = ref.watch(filteredAlertsProvider);
    final stations = ref.watch(stationsProvider).value ?? [];
    final filterStation = ref.watch(alertStationFilterProvider);
    final totalCount = ref.watch(alertCountProvider);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlertsHeader(
                totalCount: totalCount,
                stations: stations,
                filterStation: filterStation,
                isDark: isDark,
                ref: ref,
              ),
              Expanded(
                child: alertsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (_) {
                    if (filtered.isEmpty) {
                      return _EmptyAlerts(isDark: isDark);
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _AlertCard(alert: filtered[i], isDark: isDark),
                    );
                  },
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
class _AlertsHeader extends StatelessWidget {
  final int totalCount;
  final List<dynamic> stations;
  final String? filterStation;
  final bool isDark;
  final WidgetRef ref;

  const _AlertsHeader({
    required this.totalCount,
    required this.stations,
    required this.filterStation,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS CENTER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    'Active Alerts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: totalCount > 0
                      ? AppColors.criticalBg
                      : (isDark
                            ? AppColors.darkCard
                            : Colors.white.withValues(alpha: 0.65)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: totalCount > 0
                        ? AppColors.critical.withValues(alpha: 0.3)
                        : (isDark
                              ? AppColors.darkCardBorder
                              : Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
                child: Text(
                  '$totalCount ITEM${totalCount != 1 ? 'S' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: totalCount > 0 ? AppColors.critical : subColor,
                  ),
                ),
              ),
            ],
          ),

          Text(
            'Real-time hazards detected across campus sensors.',
            style: TextStyle(fontSize: 11, color: subColor),
          ),

          const SizedBox(height: 10),

          // Legend
          Row(
            children: [
              _LegendDot('Advisory', AppColors.moderate, subColor),
              const SizedBox(width: 12),
              _LegendDot('Warning', AppColors.warning, subColor),
              const SizedBox(width: 12),
              _LegendDot('Critical', AppColors.critical, subColor),
            ],
          ),

          const SizedBox(height: 10),

          // Station filter chips
          if (stations.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: filterStation == null,
                    isDark: isDark,
                    onTap: () =>
                        ref.read(alertStationFilterProvider.notifier).state =
                            null,
                  ),
                  ...stations.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FilterChip(
                        label: s.name,
                        isSelected: filterStation == s.id,
                        isDark: isDark,
                        onTap: () =>
                            ref
                                    .read(alertStationFilterProvider.notifier)
                                    .state =
                                s.id,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _LegendDot(this.label, this.color, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.06,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightText
              : (isDark
                    ? AppColors.darkCard
                    : Colors.white.withValues(alpha: 0.65)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.lightText
                : (isDark
                      ? AppColors.darkCardBorder
                      : Colors.white.withValues(alpha: 0.9)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool isDark;

  const _AlertCard({required this.alert, required this.isDark});

  Color get _borderColor {
    switch (alert.level) {
      case AlertLevel.advisory:
        return AppColors.moderate;
      case AlertLevel.warning:
        return AppColors.warning;
      case AlertLevel.critical:
        return AppColors.critical;
      case AlertLevel.sensorFailure:
        return AppColors.offline;
    }
  }

  Color get _iconBg {
    switch (alert.level) {
      case AlertLevel.advisory:
        return AppColors.moderateBg;
      case AlertLevel.warning:
        return AppColors.warningBg;
      case AlertLevel.critical:
        return AppColors.criticalBg;
      case AlertLevel.sensorFailure:
        return AppColors.offlineBg;
    }
  }

  String get _levelLabel {
    switch (alert.level) {
      case AlertLevel.advisory:
        return 'Advisory';
      case AlertLevel.warning:
        return 'Warning';
      case AlertLevel.critical:
        return 'Critical';
      case AlertLevel.sensorFailure:
        return 'Sensor Failure';
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get _actionLabel {
    switch (alert.level) {
      case AlertLevel.advisory:
        return 'Dismiss';
      case AlertLevel.warning:
        return 'Investigate';
      case AlertLevel.critical:
        return 'Investigate';
      case AlertLevel.sensorFailure:
        return 'Reboot';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
        ),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
          top: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
          right: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: _borderColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.parameter} ${_levelLabel}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_timeAgo.toUpperCase()} · REPORTED BY ${alert.sensorCode}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              // Station location chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightInput,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightInputBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 10, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      alert.stationName,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Dismiss button
              GestureDetector(
                onTap: () => FirebaseService.instance.resolveAlert(alert.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.critical,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Action button
              GestureDetector(
                onTap: () {
                  if (alert.level == AlertLevel.sensorFailure) {
                    FirebaseService.instance.sendCommand(
                      alert.stationId,
                      'restart',
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_actionLabel}ing ${alert.stationName}...',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _actionLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty alerts ──────────────────────────────────────────────────────
class _EmptyAlerts extends StatelessWidget {
  final bool isDark;
  const _EmptyAlerts({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.good.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Environment Stable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All sensors are within safe limits.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
