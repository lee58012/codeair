import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { pm25, pm10, temperature, humidity, co2, system }
enum AlertSeverity { info, warning, danger, push }

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final double value;
  final String message;
  final DateTime timestamp;
  final String deviceId;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.value,
    required this.message,
    required this.timestamp,
    required this.deviceId,
    this.isRead = false,
  });

  /// 로컬 시스템 이벤트용 팩토리 (자동 읽음 처리)
  factory AlertModel.local({
    required AlertSeverity severity,
    required String message,
    AlertType type = AlertType.system,
    double value = 0,
    String deviceId = 'system',
  }) =>
      AlertModel(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        severity: severity,
        value: value,
        message: message,
        timestamp: DateTime.now(),
        deviceId: deviceId,
        isRead: true,
      );

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      id: doc.id,
      type: AlertType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AlertType.pm25,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      value: (data['value'] ?? 0).toDouble(),
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceId: data['deviceId'] ?? 'unknown',
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'severity': severity.name,
    'value': value,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'deviceId': deviceId,
    'isRead': isRead,
  };

  String get typeLabel {
    switch (type) {
      case AlertType.pm25:        return '초미세먼지(PM2.5)';
      case AlertType.pm10:        return '미세먼지(PM10)';
      case AlertType.temperature: return '온도';
      case AlertType.humidity:    return '습도';
      case AlertType.co2:         return '이산화탄소(CO₂)';
      case AlertType.system:      return '시스템';
    }
  }
}
