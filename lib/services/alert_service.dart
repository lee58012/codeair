import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/sensor_data.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 기본 경보 임계값 (사용자가 설정 미변경 시 사용)
  static const double pm25WarningThreshold = 35.0;
  static const double pm10WarningThreshold = 80.0;
  static const double tempHighWarning     = 33.0;
  static const double tempLowWarning      = 0.0;
  static const double humidityHighWarning = 60.0;
  static const double humidityLowWarning  = 40.0;

  /// 센서 데이터 분석 후 경보 생성
  /// [pm25Threshold], [pm10Threshold]: 설정에서 저장된 사용자 임계값
  Future<void> checkAndCreateAlerts(
    SensorData data, {
    double? pm25Threshold,
    double? pm10Threshold,
  }) async {
    final double p25 = pm25Threshold ?? pm25WarningThreshold;
    final double p10 = pm10Threshold ?? pm10WarningThreshold;

    final List<AlertModel> alerts = [];

    if (data.pm25 >= p25) {
      alerts.add(_createAlert(
        type: AlertType.pm25,
        severity: AlertSeverity.warning,
        value: data.pm25,
        message: '초미세먼지(PM2.5) 기준 초과: ${data.pm25.toStringAsFixed(1)} µg/m³ (기준: ${p25.toStringAsFixed(0)})',
        deviceId: data.deviceId,
      ));
    }

    if (data.pm10 >= p10) {
      alerts.add(_createAlert(
        type: AlertType.pm10,
        severity: AlertSeverity.warning,
        value: data.pm10,
        message: '미세먼지(PM10) 기준 초과: ${data.pm10.toStringAsFixed(1)} µg/m³ (기준: ${p10.toStringAsFixed(0)})',
        deviceId: data.deviceId,
      ));
    }

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

    if (data.humidity > humidityHighWarning) {
      alerts.add(_createAlert(
        type: AlertType.humidity,
        severity: AlertSeverity.warning,
        value: data.humidity,
        message: '고습도 경보: ${data.humidity.toStringAsFixed(1)} %',
        deviceId: data.deviceId,
      ));
    } else if (data.humidity < humidityLowWarning) {
      alerts.add(_createAlert(
        type: AlertType.humidity,
        severity: AlertSeverity.warning,
        value: data.humidity,
        message: '저습도 경보: ${data.humidity.toStringAsFixed(1)} %',
        deviceId: data.deviceId,
      ));
    }

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

  Stream<List<AlertModel>> alertsStream({int limit = 50}) {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AlertModel.fromFirestore).toList());
  }

  Stream<int> unreadCountStream() {
    return _firestore
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({'isRead': true});
  }

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
