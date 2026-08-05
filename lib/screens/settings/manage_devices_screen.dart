import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_background.dart';
import '../../models/station_model.dart';
import '../../providers/station_provider.dart';
import '../../services/firebase_service.dart';

class ManageDevicesScreen extends ConsumerWidget {
  const ManageDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stationsAsync = ref.watch(stationsProvider);
    final userId = ref.watch(userIdProvider);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEVICES',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                        Text(
                          'Manage Devices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: stationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (stations) => ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      ...stations.map(
                        (s) => _DeviceCard(station: s, isDark: isDark),
                      ),
                      const SizedBox(height: 16),
                      // Add device button
                      GestureDetector(
                        onTap: () => _showAddDevice(context, userId, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Add New Device',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  void _showAddDevice(BuildContext context, String userId, bool isDark) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2535) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'Station ID (e.g. AG-001)',
                  hintText: 'Must match firmware ID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Station Name',
                  hintText: 'e.g. Computer Engineering',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Rooftop · Block A',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                    return;
                  }
                  await FirebaseService.instance.addStation(
                    stationId: idCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    ownerId: userId,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Add Device',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Device card ───────────────────────────────────────────────────────
class _DeviceCard extends ConsumerWidget {
  final StationModel station;
  final bool isDark;

  const _DeviceCard({required this.station, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      station.id,
                      style: TextStyle(
                        fontSize: 10,
                        color: subColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      station.location,
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: station.isOnline
                          ? AppColors.good
                          : AppColors.offline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    station.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: station.isOnline
                          ? AppColors.good
                          : AppColors.offline,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Rename
              _ActionBtn(
                label: 'Rename',
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: () => _showRename(context, station, isDark),
              ),
              const SizedBox(width: 6),
              // Ping / Restart if offline
              if (!station.isOnline) ...[
                _ActionBtn(
                  label: 'Ping',
                  icon: Icons.wifi_find,
                  color: AppColors.primary,
                  onTap: () {
                    FirebaseService.instance.sendCommand(station.id, 'ping');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ping sent to ${station.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  label: 'Restart',
                  icon: Icons.restart_alt,
                  color: AppColors.moderate,
                  onTap: () {
                    FirebaseService.instance.sendCommand(station.id, 'restart');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restart sent to ${station.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              // Remove
              _ActionBtn(
                label: 'Remove',
                icon: Icons.delete_outline,
                color: AppColors.critical,
                onTap: () => _confirmRemove(context, ref, station),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRename(BuildContext context, StationModel station, bool isDark) {
    final ctrl = TextEditingController(text: station.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Station'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Station name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                FirebaseService.instance.renameStation(
                  station.id,
                  ctrl.text.trim(),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    StationModel station,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
          'Remove "${station.name}"? All its data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseService.instance.removeStation(station.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.critical),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
