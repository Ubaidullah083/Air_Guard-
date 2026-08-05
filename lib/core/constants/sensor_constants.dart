import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Sensor metadata ───────────────────────────────────────────────────
class SensorInfo {
  final String key;
  final String sensorCode;
  final String fullName;
  final String unit;
  final String category;
  final double defaultElevated;
  final double defaultCritical;
  final bool isActive;

  const SensorInfo({
    required this.key,
    required this.sensorCode,
    required this.fullName,
    required this.unit,
    required this.category,
    required this.defaultElevated,
    required this.defaultCritical,
    this.isActive = false,
  });
}

class SensorConstants {
  SensorConstants._();

  static const List<SensorInfo> sensors = [
    // Particulate Matter
    SensorInfo(
      key: 'dust',
      sensorCode: 'GP2Y1010',
      fullName: 'Dust Density',
      unit: 'μg/m³',
      category: 'Particulate Matter',
      defaultElevated: 35,
      defaultCritical: 75,
      isActive: false,
    ),
    SensorInfo(
      key: 'pm25',
      sensorCode: 'PMS5003',
      fullName: 'PM2.5 Level',
      unit: 'μg/m³',
      category: 'Particulate Matter',
      defaultElevated: 12,
      defaultCritical: 35,
      isActive: false,
    ),
    // Gas Detection
    SensorInfo(
      key: 'mq4',
      sensorCode: 'MQ4',
      fullName: 'Methane / CNG',
      unit: 'ppm',
      category: 'Gas Detection',
      defaultElevated: 33,
      defaultCritical: 40,
      isActive: true,
    ),
    SensorInfo(
      key: 'mq7',
      sensorCode: 'MQ7',
      fullName: 'Carbon Monoxide',
      unit: 'ppm',
      category: 'Gas Detection',
      defaultElevated: 9,
      defaultCritical: 35,
      isActive: false,
    ),
    SensorInfo(
      key: 'mq131',
      sensorCode: 'MQ131',
      fullName: 'Ozone (O3)',
      unit: 'ppb',
      category: 'Gas Detection',
      defaultElevated: 54,
      defaultCritical: 70,
      isActive: false,
    ),
    SensorInfo(
      key: 'mq135',
      sensorCode: 'MQ135',
      fullName: 'Air Quality / VOC',
      unit: 'ppm',
      category: 'Gas Detection',
      defaultElevated: 150,
      defaultCritical: 300,
      isActive: true,
    ),
    // Environment
    SensorInfo(
      key: 'humidity',
      sensorCode: 'DHT22',
      fullName: 'Rel. Humidity',
      unit: '%',
      category: 'Environment',
      defaultElevated: 70,
      defaultCritical: 85,
      isActive: true,
    ),
    SensorInfo(
      key: 'temperature',
      sensorCode: 'DHT22',
      fullName: 'Temperature',
      unit: '°C',
      category: 'Environment',
      defaultElevated: 35,
      defaultCritical: 40,
      isActive: true,
    ),
  ];

  // Quick lookup by key
  static SensorInfo? byKey(String key) {
    try {
      return sensors.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  static List<String> get categories =>
      sensors.map((s) => s.category).toSet().toList();

  static List<SensorInfo> byCategory(String category) =>
      sensors.where((s) => s.category == category).toList();
}

// ── AQI level helper ──────────────────────────────────────────────────
enum AirQualityLevel { good, moderate, warning, critical, offline }

class AirQualityHelper {
  static AirQualityLevel getLevel(
    double value,
    double elevated,
    double critical,
  ) {
    if (value >= critical) return AirQualityLevel.critical;
    if (value >= elevated * 0.85) return AirQualityLevel.warning;
    if (value >= elevated * 0.6) return AirQualityLevel.moderate;
    return AirQualityLevel.good;
  }

  static String getLabel(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return 'Normal';
      case AirQualityLevel.moderate:
        return 'Elevated';
      case AirQualityLevel.warning:
        return 'Warning';
      case AirQualityLevel.critical:
        return 'Critical';
      case AirQualityLevel.offline:
        return 'Offline';
    }
  }

  static String getAdvice(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return 'Air quality is good. Safe for all activities.';
      case AirQualityLevel.moderate:
        return 'Air quality is acceptable. Sensitive groups take care.';
      case AirQualityLevel.warning:
        return 'Sensitive groups should reduce prolonged outdoor exertion.';
      case AirQualityLevel.critical:
        return 'Hazardous air quality. Evacuate or use filtration immediately.';
      case AirQualityLevel.offline:
        return 'Station offline. No data available.';
    }
  }

  static Color getColor(AirQualityLevel level, {bool dark = false}) {
    switch (level) {
      case AirQualityLevel.good:
        return dark ? AppColors.darkGood : AppColors.good;
      case AirQualityLevel.moderate:
        return dark ? AppColors.darkModerate : AppColors.moderate;
      case AirQualityLevel.warning:
        return dark ? AppColors.darkWarning : AppColors.warning;
      case AirQualityLevel.critical:
        return dark ? AppColors.darkCritical : AppColors.critical;
      case AirQualityLevel.offline:
        return AppColors.offline;
    }
  }

  static Color getBgColor(AirQualityLevel level, {bool dark = false}) {
    switch (level) {
      case AirQualityLevel.good:
        return dark ? AppColors.darkGoodBg : AppColors.goodBg;
      case AirQualityLevel.moderate:
        return dark ? AppColors.darkModerateBg : AppColors.moderateBg;
      case AirQualityLevel.warning:
        return dark ? AppColors.darkWarningBg : AppColors.warningBg;
      case AirQualityLevel.critical:
        return dark ? AppColors.darkCriticalBg : AppColors.criticalBg;
      case AirQualityLevel.offline:
        return AppColors.offlineBg;
    }
  }
}
