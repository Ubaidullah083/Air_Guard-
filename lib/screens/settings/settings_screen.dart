import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../../core/widgets/animated_background.dart';
import '../../providers/station_provider.dart';
import '../../services/firebase_service.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Threshold controllers per sensor key
  final Map<String, TextEditingController> _elevatedCtrls = {};
  final Map<String, TextEditingController> _criticalCtrls = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _elevatedCtrls.values) c.dispose();
    for (final c in _criticalCtrls.values) c.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, double> thresholds) {
    for (final sensor in SensorConstants.sensors) {
      final eKey = '${sensor.key}_elevated';
      final cKey = '${sensor.key}_critical';
      if (!_elevatedCtrls.containsKey(sensor.key)) {
        _elevatedCtrls[sensor.key] = TextEditingController(
          text: (thresholds[eKey] ?? sensor.defaultElevated).toStringAsFixed(0),
        );
        _criticalCtrls[sensor.key] = TextEditingController(
          text: (thresholds[cKey] ?? sensor.defaultCritical).toStringAsFixed(0),
        );
      }
    }
  }

  Future<void> _saveThresholds(String stationId) async {
    setState(() => _saving = true);
    for (final sensor in SensorConstants.sensors) {
      final elevated =
          double.tryParse(_elevatedCtrls[sensor.key]?.text ?? '') ??
          sensor.defaultElevated;
      final critical =
          double.tryParse(_criticalCtrls[sensor.key]?.text ?? '') ??
          sensor.defaultCritical;
      await FirebaseService.instance.updateThreshold(
        stationId,
        '${sensor.key}_elevated',
        elevated,
      );
      await FirebaseService.instance.updateThreshold(
        stationId,
        '${sensor.key}_critical',
        critical,
      );
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thresholds saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.good,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final stationAsync = ref.watch(selectedStationProvider);
    final station = stationAsync.value;
    final stations = ref.watch(stationsProvider).value ?? [];

    if (station != null) _initControllers(station.thresholds);

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final cardColor = isDark
        ? AppColors.darkCard
        : Colors.white.withValues(alpha: 0.65);
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : Colors.white.withValues(alpha: 0.9);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTROL PANEL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Appearance ────────────────────────────
              _SectionLabel('Appearance', subColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SettingsCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.moderateBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.dark_mode,
                            color: AppColors.moderate,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Easier on the eyes at night',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: subColor,
                                  letterSpacing: 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Target device ─────────────────────────
              _SectionLabel('Target Device', subColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: stations.map((s) {
                        final isSelected =
                            s.id == ref.watch(selectedStationIdProvider);
                        return GestureDetector(
                          onTap: () =>
                              ref
                                      .read(selectedStationIdProvider.notifier)
                                      .state =
                                  s.id,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lightText
                                  : cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.lightText
                                    : borderColor,
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
                                    color: s.isOnline
                                        ? AppColors.good
                                        : AppColors.offline,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  s.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── Thresholds ────────────────────────────
              _SectionLabel('Alert Thresholds', subColor),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final sensor = SensorConstants.sensors[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ThresholdCard(
                      sensor: sensor,
                      elevatedCtrl:
                          _elevatedCtrls[sensor.key] ?? TextEditingController(),
                      criticalCtrl:
                          _criticalCtrls[sensor.key] ?? TextEditingController(),
                      isDark: isDark,
                    ),
                  );
                }, childCount: SensorConstants.sensors.length),
              ),

              // Save button
              if (station != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.good,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () => _saveThresholds(station.id),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Thresholds',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),

              // ── Data Operations ───────────────────────
              _SectionLabel('Data Operations', subColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SettingsCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.download,
                          iconColor: AppColors.good,
                          label: 'Export Local History',
                          isDark: isDark,
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exporting...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              ),
                        ),
                        Divider(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          height: 1,
                        ),
                        _SettingsTile(
                          icon: Icons.upload,
                          iconColor: AppColors.primary,
                          label: 'Restore from Backup',
                          isDark: isDark,
                          onTap: () {},
                        ),
                        Divider(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          height: 1,
                        ),
                        _SettingsTile(
                          icon: Icons.delete_outline,
                          iconColor: AppColors.critical,
                          label: 'Clear Local Cache',
                          textColor: AppColors.critical,
                          isDark: isDark,
                          onTap: () => _confirmClear(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Manage Devices ────────────────────────
              _SectionLabel('Devices', subColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SettingsCard(
                    isDark: isDark,
                    child: _SettingsTile(
                      icon: Icons.sensors,
                      iconColor: AppColors.primary,
                      label: 'Manage Devices',
                      trailing: Icons.chevron_right,
                      isDark: isDark,
                      onTap: () => context.push('/settings/devices'),
                    ),
                  ),
                ),
              ),

              // ── About ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Center(
                    child: Text(
                      'Air Guard · ESP32-WROOM-32 · v1.0.0\n'
                      'Designed and powered by COMSATS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: subColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all locally stored data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.critical),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Threshold card ────────────────────────────────────────────────────
class _ThresholdCard extends StatelessWidget {
  final SensorInfo sensor;
  final TextEditingController elevatedCtrl;
  final TextEditingController criticalCtrl;
  final bool isDark;

  const _ThresholdCard({
    required this.sensor,
    required this.elevatedCtrl,
    required this.criticalCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final inputColor = isDark ? AppColors.darkInput : AppColors.lightInput;
    final inputBorder = isDark
        ? AppColors.darkInputBorder
        : AppColors.lightInputBorder;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sensor.sensorCode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                ' — ${sensor.fullName}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: subColor,
                ),
              ),
              const Spacer(),
              Text(
                sensor.unit,
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ELEVATED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.moderate,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: elevatedCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.moderate,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRITICAL',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.critical,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: criticalCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: AppColors.critical,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.12,
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? textColor;
  final IconData? trailing;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tc = textColor ?? (isDark ? AppColors.darkText : AppColors.lightText);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tc),
      ),
      trailing: trailing != null
          ? Icon(
              trailing,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              size: 18,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
    );
  }
}
