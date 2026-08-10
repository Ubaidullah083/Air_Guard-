import '../models/sensor_reading_model.dart';
import '../models/station_model.dart';
import '../models/alert_model.dart';
import '../core/constants/sensor_constants.dart';
import 'firebase_service.dart';

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  // Track which sensors already have active alerts
  // so we don't spam duplicates
  final Set<String> _activeAlertKeys = {};

  Future<void> evaluateReading(
    SensorReadingModel reading,
    StationModel station,
  ) async {
    for (final sensor in SensorConstants.sensors) {
      if (!sensor.isActive) continue; // ✅ skip inactive sensors

      final value = reading.getValue(sensor.key);
      final elevatedKey = '${sensor.key}_elevated';
      final criticalKey = '${sensor.key}_critical';
      final elevated =
          station.thresholds[elevatedKey] ?? sensor.defaultElevated;
      final critical =
          station.thresholds[criticalKey] ?? sensor.defaultCritical;

      // Unique key per station + sensor combination
      final alertKey = '${station.id}_${sensor.key}';

      AlertLevel? level;
      String? message;

      if (value >= critical) {
        level = AlertLevel.critical;
        message =
            '${value.toStringAsFixed(1)} ${sensor.unit} '
            'exceeds safety limits';
      } else if (value >= elevated) {
        level = AlertLevel.warning;
        message =
            '${value.toStringAsFixed(1)} ${sensor.unit} '
            'is approaching limit';
      }

      if (level != null && message != null) {
        // ✅ Only create alert if not already active for this sensor
        if (!_activeAlertKeys.contains(alertKey)) {
          _activeAlertKeys.add(alertKey);

          final alert = AlertModel(
            id: '',
            stationId: station.id,
            stationName: station.name,
            sensorKey: sensor.key,
            sensorCode: sensor.sensorCode,
            parameter: sensor.fullName,
            value: value,
            unit: sensor.unit,
            level: level,
            message: message,
            timestamp: DateTime.now(), // ✅ always use current real time
            resolved: false,
          );
          await FirebaseService.instance.createAlert(alert);
        }
      } else {
        // ✅ Reading is back to normal — remove from active set
        // so a new alert can be created if it spikes again later
        _activeAlertKeys.remove(alertKey);
      }
    }
  }

  // Call this when an alert is dismissed
  void clearActiveAlert(String stationId, String sensorKey) {
    _activeAlertKeys.remove('${stationId}_${sensorKey}');
  }
}
