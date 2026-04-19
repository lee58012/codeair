import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { pm25, pm10, temperature, humidity }
enum AlertSeverity { warning, danger }

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

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'value': value,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceId': deviceId,
      'isRead': isRead,
    };
  }

  String get typeLabel {
    switch (type) {
      case AlertType.pm25:
        return '초미세먼지(PM2.5)';
      case AlertType.pm10:
        return '미세먼지(PM10)';
      case AlertType.temperature:
        return '온도';
      case AlertType.humidity:
        return '습도';
    }
  }
}
