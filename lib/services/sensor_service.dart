import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class SensorService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// 최신 센서 데이터 실시간 스트림
  Stream<SensorData?> latestSensorStream(String deviceId) {
    return _db
        .child('devices/$deviceId/latest')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return SensorData.fromMap(map, event.snapshot.key ?? 'unknown');
    });
  }

  /// 최근 N개 히스토리 데이터
  Future<List<SensorData>> fetchHistory({
    required String deviceId,
    int limit = 24,
  }) async {
    final snapshot = await _db
        .child('devices/$deviceId/history')
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final map = snapshot.value as Map<dynamic, dynamic>;
    return map.entries
        .map((e) => SensorData.fromMap(e.value as Map, e.key as String))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// 히스토리 실시간 스트림 (최근 24개)
  Stream<List<SensorData>> historyStream(String deviceId) {
    return _db
        .child('devices/$deviceId/history')
        .orderByChild('timestamp')
        .limitToLast(24)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map((e) => SensorData.fromMap(e.value as Map, e.key as String))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  /// 테스트용 더미 데이터 전송
  Future<void> pushDummyData(String deviceId) async {
    final rng = Random();
    final now = DateTime.now();
    final data = {
      'pm25':        double.parse((rng.nextDouble() * 90).toStringAsFixed(1)),        // 0 ~ 90
      'pm10':        double.parse((rng.nextDouble() * 170).toStringAsFixed(1)),       // 0 ~ 170
      'temperature': double.parse((-10 + rng.nextDouble() * 48).toStringAsFixed(1)), // -10 ~ 38
      'humidity':    double.parse((30 + rng.nextDouble() * 40).toStringAsFixed(1)),   // 30 ~ 70
      'timestamp': now.millisecondsSinceEpoch,
      'deviceId': deviceId,
    };
    await _db.child('devices/$deviceId/latest').set(data);
    await _db.child('devices/$deviceId/history').push().set(data);
  }
}
