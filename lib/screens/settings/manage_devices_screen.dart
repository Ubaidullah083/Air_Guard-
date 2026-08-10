import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
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
    final aqiLevel = ref.watch(globalAqiLevelProvider);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AnimatedBackground(
      aqiLevel: aqiLevel, // ✅ follows global background pattern
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────
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

              // ── Device list ────────────────────────────
              Expanded(
                child: stationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (stations) => ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      // Device cards
                      ...stations.map(
                        (s) => _DeviceCard(station: s, isDark: isDark),
                      ),

                      const SizedBox(height: 16),

                      // ── Add new device button ──────────
                      GestureDetector(
                        onTap: () => _showAddDevice(context, userId, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
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

                      const SizedBox(height: 8),

                      // ── Recycle bin button ─────────────
                      GestureDetector(
                        onTap: () =>
                            _showRecycleBin(context, ref, userId, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restore_from_trash,
                                color: subColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recycle Bin',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subColor,
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

  // ── Add device bottom sheet ─────────────────────────
  void _showAddDevice(BuildContext context, String userId, bool isDark) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
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
              // Drag handle
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
              const SizedBox(height: 6),
              Text(
                'Station ID must match the STATION_ID in your ESP32 firmware exactly.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'Station ID',
                  hintText: 'e.g. AG-001',
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
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
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

  // ── Recycle bin bottom sheet ────────────────────────
  void _showRecycleBin(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _RecycleBinSheet(userId: userId, isDark: isDark),
    );
  }
}

// ── Recycle bin sheet ─────────────────────────────────────────────────
class _RecycleBinSheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const _RecycleBinSheet({required this.userId, required this.isDark});

  @override
  ConsumerState<_RecycleBinSheet> createState() => _RecycleBinSheetState();
}

class _RecycleBinSheetState extends ConsumerState<_RecycleBinSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await FirebaseService.instance.getRecycleBin(widget.userId);
    if (mounted)
      setState(() {
        _items = items;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = widget.isDark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A2535) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkSubtext
                    : AppColors.lightMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.restore_from_trash, color: subColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recycle Bin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Restore a device to recover its data and history.',
            style: TextStyle(fontSize: 11, color: subColor),
          ),
          const SizedBox(height: 16),

          // Content
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: AppColors.good,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recycle bin is empty',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final info = item['info'] as Map? ?? {};
                      final name =
                          info['name']?.toString() ?? item['id'].toString();
                      final location = info['location']?.toString() ?? '';
                      final stationId = item['id'].toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.darkCard
                              : AppColors.lightInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightInputBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    stationId,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: subColor,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  if (location.isNotEmpty)
                                    Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: subColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Restore button
                            GestureDetector(
                              onTap: () async {
                                await FirebaseService.instance.restoreStation(
                                  stationId,
                                );
                                await _load();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$name restored!'),
                                      backgroundColor: AppColors.good,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.good.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Restore',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.good,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
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
                    if (station.location.isNotEmpty)
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
              _ActionBtn(
                label: 'Rename',
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: () => _showRename(context, station, isDark),
              ),
              const SizedBox(width: 6),

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

  // ── Rename dialog ───────────────────────────────────
  void _showRename(BuildContext context, StationModel station, bool isDark) {
    final ctrl = TextEditingController(text: station.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Station'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Station name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Remove confirm dialog ───────────────────────────
  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    StationModel station,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
          'Remove "${station.name}"?\n\nData will be moved to Recycle Bin — you can restore it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // dismiss first
              await FirebaseService.instance.removeStation(station.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${station.name} moved to Recycle Bin'),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () =>
                          FirebaseService.instance.restoreStation(station.id),
                    ),
                  ),
                );
              }
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

// ── Action button ─────────────────────────────────────────────────────
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
