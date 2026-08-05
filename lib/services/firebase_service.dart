import 'package:firebase_database/firebase_database.dart';
import '../models/station_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/alert_model.dart';
import '../core/constants/sensor_constants.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _db = FirebaseDatabase.instance;

  // ── Station refs ─────────────────────────────────────
  DatabaseReference _stationRef(String id) => _db.ref('stations/$id');
  DatabaseReference _stationInfoRef(String id) => _db.ref('stations/$id/info');
  DatabaseReference _stationConfigRef(String id) =>
      _db.ref('stations/$id/config');
  DatabaseReference _readingsRef(String id) => _db.ref('stations/$id/readings');
  DatabaseReference _commandRef(String id) =>
      _db.ref('stations/$id/config/command');
  DatabaseReference get _alertsRef => _db.ref('alerts');

  // ── Get all stations for a user ───────────────────────
  Stream<List<StationModel>> watchUserStations(String userId) {
    return _db.ref('stations').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries
          .where((e) {
            final info = (e.value as Map?)?['info'] as Map?;
            return info?['owner']?.toString() == userId;
          })
          .map((e) => StationModel.fromMap(e.key.toString(), e.value as Map))
          .toList();
    });
  }

  // ── Watch single station ──────────────────────────────
  Stream<StationModel?> watchStation(String stationId) {
    return _stationRef(stationId).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return StationModel.fromMap(stationId, data);
    });
  }

  // ── Watch latest reading ──────────────────────────────
  Stream<SensorReadingModel?> watchLatestReading(String stationId) {
    return _readingsRef(stationId).orderByKey().limitToLast(1).onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      final entry = data.entries.last;
      return SensorReadingModel.fromMap(stationId, entry.value as Map);
    });
  }

  // ── Watch readings history ────────────────────────────
  Stream<List<SensorReadingModel>> watchReadingsHistory(
    String stationId, {
    int limitToLast = 60,
  }) {
    return _readingsRef(
      stationId,
    ).orderByKey().limitToLast(limitToLast).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];
      return data.entries
          .map((e) => SensorReadingModel.fromMap(stationId, e.value as Map))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  // ── Watch all alerts ──────────────────────────────────
  Stream<List<AlertModel>> watchAlerts({String? stationId}) {
    return _alertsRef.orderByChild('resolved').equalTo(false).onValue.map((
      event,
    ) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];
      final alerts =
          data.entries
              .map((e) => AlertModel.fromMap(e.key.toString(), e.value as Map))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (stationId != null) {
        return alerts.where((a) => a.stationId == stationId).toList();
      }
      return alerts;
    });
  }

  // ── Add station ───────────────────────────────────────
  Future<void> addStation({
    required String stationId,
    required String name,
    required String location,
    required String ownerId,
  }) async {
    // Build default thresholds from sensor constants
    final thresholds = <String, dynamic>{};
    for (final s in SensorConstants.sensors) {
      thresholds['${s.key}_elevated'] = s.defaultElevated;
      thresholds['${s.key}_critical'] = s.defaultCritical;
    }

    await _stationRef(stationId).set({
      'info': {
        'name': name,
        'location': location,
        'owner': ownerId,
        'status': 'offline',
        'lastSeen': DateTime.now().toIso8601String(),
      },
      'config': {'thresholds': thresholds, 'command': ''},
    });
  }

  // ── Remove station ────────────────────────────────────
  Future<void> removeStation(String stationId) async {
    await _stationRef(stationId).remove();
  }

  // ── Rename station ────────────────────────────────────
  Future<void> renameStation(String stationId, String name) async {
    await _stationInfoRef(stationId).update({'name': name});
  }

  // ── Update location ───────────────────────────────────
  Future<void> updateLocation(String stationId, String location) async {
    await _stationInfoRef(stationId).update({'location': location});
  }

  // ── Update thresholds ─────────────────────────────────
  Future<void> updateThreshold(
    String stationId,
    String key,
    double value,
  ) async {
    await _stationConfigRef(stationId).child('thresholds/$key').set(value);
  }

  // ── Send command to device ────────────────────────────
  Future<void> sendCommand(String stationId, String command) async {
    await _commandRef(stationId).set(command);
  }

  // ── Create alert ──────────────────────────────────────
  Future<void> createAlert(AlertModel alert) async {
    final ref = _alertsRef.push();
    await ref.set(alert.toMap());
  }

  // ── Resolve / dismiss alert ───────────────────────────
  Future<void> resolveAlert(String alertId) async {
    await _alertsRef.child(alertId).update({'resolved': true});
  }

  // ── Get 24h worst reading per sensor ─────────────────
  Future<Map<String, double>> getWorst24h(String stationId) async {
    final cutoff = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch
        .toString();

    final snap = await _readingsRef(
      stationId,
    ).orderByKey().startAt(cutoff).get();

    final data = snap.value as Map?;
    if (data == null) return {};

    final readings = data.values
        .map((v) => SensorReadingModel.fromMap(stationId, v as Map))
        .toList();

    final worst = <String, double>{};
    for (final s in SensorConstants.sensors) {
      if (readings.isEmpty) {
        worst[s.key] = 0;
      } else {
        worst[s.key] = readings
            .map((r) => r.getValue(s.key))
            .reduce((a, b) => a > b ? a : b);
      }
    }
    return worst;
  }
}
