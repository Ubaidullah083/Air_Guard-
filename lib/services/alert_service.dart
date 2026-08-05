import '../models/sensor_reading_model.dart';
import '../models/station_model.dart';
import '../models/alert_model.dart';
import '../core/constants/sensor_constants.dart';
import 'firebase_service.dart';

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  Future<void> evaluateReading(
    SensorReadingModel reading,
    StationModel station,
  ) async {
    for (final sensor in SensorConstants.sensors) {
      final value = reading.getValue(sensor.key);
      final elevatedKey = '${sensor.key}_elevated';
      final criticalKey = '${sensor.key}_critical';

      final elevated =
          station.thresholds[elevatedKey] ?? sensor.defaultElevated;
      final critical =
          station.thresholds[criticalKey] ?? sensor.defaultCritical;

      AlertLevel? level;
      String? message;

      if (value >= critical) {
        level = AlertLevel.critical;
        message =
            '${value.toStringAsFixed(1)} ${sensor.unit} exceeds safety limits';
      } else if (value >= elevated) {
        level = AlertLevel.warning;
        message =
            '${value.toStringAsFixed(1)} ${sensor.unit} is approaching limit';
      }

      if (level != null && message != null) {
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
          timestamp: reading.timestamp,
          resolved: false,
        );
        await FirebaseService.instance.createAlert(alert);
      }
    }
  }
}
