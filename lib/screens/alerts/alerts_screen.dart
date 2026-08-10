import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../models/alert_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/station_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/alert_service.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiLevel = ref.watch(globalAqiLevelProvider);
    final alertsAsync = ref.watch(allAlertsProvider);
    final filtered = ref.watch(filteredAlertsProvider);
    final stations = ref.watch(stationsProvider).value ?? [];
    final filterStation = ref.watch(alertStationFilterProvider);
    final totalCount = ref.watch(alertCountProvider);

    return AnimatedBackground(
      aqiLevel: aqiLevel,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS CENTER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A3A52),
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              'Active Alerts',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A2540),
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
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: totalCount > 0
                                  ? AppColors.critical
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            '$totalCount ITEM${totalCount != 1 ? 'S' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: totalCount > 0
                                  ? AppColors.critical
                                  : const Color(0xFF4A6880),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Real-time hazards detected across campus sensors.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1A3A52)),
                    ),

                    const SizedBox(height: 10),

                    // Legend row
                    Row(
                      children: [
                        _dot('Advisory', AppColors.moderate),
                        const SizedBox(width: 14),
                        _dot('Warning', AppColors.warning),
                        const SizedBox(width: 14),
                        _dot('Critical', AppColors.critical),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Station filter chips
                    if (stations.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('All', filterStation == null, () {
                              ref
                                      .read(alertStationFilterProvider.notifier)
                                      .state =
                                  null;
                            }),
                            ...stations.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: _chip(s.name, filterStation == s.id, () {
                                  ref
                                      .read(alertStationFilterProvider.notifier)
                                      .state = s
                                      .id;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── Alert list ──────────────────────────────────────────
              Expanded(
                child: alertsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Color(0xFF0A2540)),
                    ),
                  ),
                  data: (_) {
                    if (filtered.isEmpty) {
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
                            const Text(
                              'Environment Stable',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A2540),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'All sensors are within safe limits.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A6880),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _Card(alert: filtered[i]),
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

  // ── Inline helpers so no separate class needed ──────────────────────
  Widget _dot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A3A52),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0A2540)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF0A2540) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF4A6880),
          ),
        ),
      ),
    );
  }
}

// ── Alert card — completely standalone, zero dependency on theme ───────
class _Card extends StatelessWidget {
  final AlertModel alert;
  const _Card({required this.alert}); // ✅ no context field

  Color get _border {
    switch (alert.level) {
      case AlertLevel.advisory:
        return const Color(0xFFD97706);
      case AlertLevel.warning:
        return const Color(0xFFEA580C);
      case AlertLevel.critical:
        return const Color(0xFFDC2626);
      case AlertLevel.sensorFailure:
        return const Color(0xFF94A3B8);
    }
  }

  Color get _iconBg {
    switch (alert.level) {
      case AlertLevel.advisory:
        return const Color(0xFFFEF3C7);
      case AlertLevel.warning:
        return const Color(0xFFFFF7ED);
      case AlertLevel.critical:
        return const Color(0xFFFEE2E2);
      case AlertLevel.sensorFailure:
        return const Color(0xFFF1F5F9);
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
    final d = DateTime.now().difference(alert.timestamp);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ only one context
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          left: BorderSide(color: _border, width: 5),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alert.parameter} — $_levelLabel',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            alert.message.isNotEmpty
                ? alert.message
                : 'Reading exceeded threshold',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A6880),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${_timeAgo.toUpperCase()} · REPORTED BY ${alert.sensorCode}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A8FA8),
              letterSpacing: 0.08,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD0E0FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 11,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      alert.stationName.isNotEmpty
                          ? alert.stationName
                          : alert.stationId,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  AlertService.instance.clearActiveAlert(
                    alert.stationId,
                    alert.sensorKey,
                  );
                  FirebaseService.instance.resolveAlert(alert.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

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
                        alert.level == AlertLevel.sensorFailure
                            ? 'Reboot sent to ${alert.stationName}'
                            : 'Investigating ${alert.stationName}...',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF1565C0),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.level == AlertLevel.sensorFailure
                        ? 'Reboot'
                        : 'Investigate',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
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
