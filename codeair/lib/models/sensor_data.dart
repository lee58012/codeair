class SensorData {
  final String id;
  final double pm25;
  final double pm10;
  final double temperature;
  final double humidity;
  final double co2;
  final DateTime timestamp;
  final String deviceId;

  SensorData({
    required this.id,
    required this.pm25,
    required this.pm10,
    required this.temperature,
    required this.humidity,
    this.co2 = 0,
    required this.timestamp,
    required this.deviceId,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map, String id) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) return DateTime.now();
      if (ts is int) {
        return ts < 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
            : DateTime.fromMillisecondsSinceEpoch(ts);
      }
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return SensorData(
      id: id,
      pm25: toDouble(map['pm25']),
      pm10: toDouble(map['pm10']),
      temperature: toDouble(map['temperature']),
      humidity: toDouble(map['humidity']),
      co2: toDouble(map['co2_ppm'] ?? map['co2']),
      timestamp: parseTimestamp(map['timestamp']),
      deviceId: (map['deviceId'] ?? 'unknown').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pm25': pm25,
    'pm10': pm10,
    'temperature': temperature,
    'humidity': humidity,
    'co2_ppm': co2,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'deviceId': deviceId,
  };
}
