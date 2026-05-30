import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class SensorService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// 최신 센서 데이터 실시간 스트림
  /// IoT가 `sensors/latest` 경로에 자동 갱신 → 거기를 구독
  Stream<SensorData?> latestSensorStream(String deviceId) {
    return _db
        .child('sensors/latest')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      // IoT가 deviceId를 안 보내므로 직접 주입
      final enriched = Map<dynamic, dynamic>.from(map);
      enriched['deviceId'] = deviceId;
      return SensorData.fromMap(enriched, event.snapshot.key ?? 'latest');
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
}
