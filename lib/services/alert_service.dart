import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/sensor_data.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 경보 임계값 설정
  static const double pm25WarningThreshold = 35.0;
  static const double pm25DangerThreshold = 75.0;
  static const double pm10WarningThreshold = 80.0;
  static const double pm10DangerThreshold = 150.0;
  static const double tempHighWarning = 33.0;
  static const double tempLowWarning = 0.0;
  static const double humidityHighWarning = 80.0;
  static const double humidityLowWarning = 20.0;

  /// 센서 데이터 분석 후 경보 생성
  /// [pm25Threshold], [pm10Threshold]: 설정에서 저장된 사용자 임계값 (미지정 시 기본값 사용)
  Future<void> checkAndCreateAlerts(
    SensorData data, {
    double? pm25Threshold,
    double? pm10Threshold,
  }) async {
    final double p25Warn = pm25Threshold ?? pm25WarningThreshold;
    final double p25Danger = (pm25Threshold != null)
        ? pm25Threshold * 2.0   // 경보 기준의 2배를 위험 수준으로 설정
        : pm25DangerThreshold;
    final double p10Warn = pm10Threshold ?? pm10WarningThreshold;
    final double p10Danger = (pm10Threshold != null)
        ? pm10Threshold * 1.875 // 80→150 비율 유지
        : pm10DangerThreshold;

    final List<AlertModel> alerts = [];

    // PM2.5 체크
    if (data.pm25 >= p25Danger) {
      alerts.add(_createAlert(
        type: AlertType.pm25,
        severity: AlertSeverity.danger,
        value: data.pm25,
        message: '초미세먼지(PM2.5) 위험 수준: ${data.pm25.toStringAsFixed(1)} µg/m³',
        deviceId: data.deviceId,
      ));
    } else if (data.pm25 >= p25Warn) {
      alerts.add(_createAlert(
        type: AlertType.pm25,
        severity: AlertSeverity.warning,
        value: data.pm25,
        message: '초미세먼지(PM2.5) 나쁨: ${data.pm25.toStringAsFixed(1)} µg/m³',
        deviceId: data.deviceId,
      ));
    }

    // PM10 체크
    if (data.pm10 >= p10Danger) {
      alerts.add(_createAlert(
        type: AlertType.pm10,
        severity: AlertSeverity.danger,
        value: data.pm10,
        message: '미세먼지(PM10) 위험 수준: ${data.pm10.toStringAsFixed(1)} µg/m³',
        deviceId: data.deviceId,
      ));
    } else if (data.pm10 >= p10Warn) {
      alerts.add(_createAlert(
        type: AlertType.pm10,
        severity: AlertSeverity.warning,
        value: data.pm10,
        message: '미세먼지(PM10) 나쁨: ${data.pm10.toStringAsFixed(1)} µg/m³',
        deviceId: data.deviceId,
      ));
    }

    // 온도 체크
    if (data.temperature >= tempHighWarning) {
      alerts.add(_createAlert(
        type: AlertType.temperature,
        severity: AlertSeverity.warning,
        value: data.temperature,
        message: '고온 경보: ${data.temperature.toStringAsFixed(1)} °C',
        deviceId: data.deviceId,
      ));
    } else if (data.temperature <= tempLowWarning) {
      alerts.add(_createAlert(
        type: AlertType.temperature,
        severity: AlertSeverity.warning,
        value: data.temperature,
        message: '저온 경보: ${data.temperature.toStringAsFixed(1)} °C',
        deviceId: data.deviceId,
      ));
    }

    // 습도 체크
    if (data.humidity >= humidityHighWarning) {
      alerts.add(_createAlert(
        type: AlertType.humidity,
        severity: AlertSeverity.warning,
        value: data.humidity,
        message: '고습도 경보: ${data.humidity.toStringAsFixed(1)} %',
        deviceId: data.deviceId,
      ));
    } else if (data.humidity <= humidityLowWarning) {
      alerts.add(_createAlert(
        type: AlertType.humidity,
        severity: AlertSeverity.warning,
        value: data.humidity,
        message: '저습도 경보: ${data.humidity.toStringAsFixed(1)} %',
        deviceId: data.deviceId,
      ));
    }

    // Firestore에 저장
    for (final alert in alerts) {
      await _firestore.collection('alerts').add(alert.toMap());
    }
  }

  AlertModel _createAlert({
    required AlertType type,
    required AlertSeverity severity,
    required double value,
    required String message,
    required String deviceId,
  }) {
    return AlertModel(
      id: '',
      type: type,
      severity: severity,
      value: value,
      message: message,
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );
  }

  /// 최근 경보 스트림
  Stream<List<AlertModel>> alertsStream({int limit = 50}) {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AlertModel.fromFirestore).toList());
  }

  /// 읽지 않은 경보 수
  Stream<int> unreadCountStream() {
    return _firestore
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// 경보 읽음 처리
  Future<void> markAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({'isRead': true});
  }

  /// 전체 읽음 처리
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
