class SensorData {
  final String id;
  final double pm25;
  final double pm10;
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final String deviceId;

  SensorData({
    required this.id,
    required this.pm25,
    required this.pm10,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.deviceId,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map, String id) {
    return SensorData(
      id: id,
      pm25: (map['pm25'] ?? 0).toDouble(),
      pm10: (map['pm10'] ?? 0).toDouble(),
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      deviceId: map['deviceId'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pm25': pm25,
      'pm10': pm10,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceId': deviceId,
    };
  }

  /// 미세먼지(PM2.5) 등급
  AirQualityLevel get pm25Level {
    if (pm25 <= 15) return AirQualityLevel.good;
    if (pm25 <= 35) return AirQualityLevel.moderate;
    if (pm25 <= 75) return AirQualityLevel.bad;
    return AirQualityLevel.veryBad;
  }

  /// 미세먼지(PM10) 등급
  AirQualityLevel get pm10Level {
    if (pm10 <= 30) return AirQualityLevel.good;
    if (pm10 <= 80) return AirQualityLevel.moderate;
    if (pm10 <= 150) return AirQualityLevel.bad;
    return AirQualityLevel.veryBad;
  }

  /// 온도 상태
  TemperatureLevel get temperatureLevel {
    if (temperature < 0) return TemperatureLevel.cold;
    if (temperature <= 18) return TemperatureLevel.cool;
    if (temperature <= 26) return TemperatureLevel.comfortable;
    if (temperature <= 33) return TemperatureLevel.warm;
    return TemperatureLevel.hot;
  }

  /// 습도 상태
  HumidityLevel get humidityLevel {
    if (humidity < 30) return HumidityLevel.dry;
    if (humidity <= 60) return HumidityLevel.comfortable;
    return HumidityLevel.humid;
  }

  /// 전체 공기질 경보 여부
  bool get hasAlert =>
      pm25Level == AirQualityLevel.bad ||
      pm25Level == AirQualityLevel.veryBad ||
      pm10Level == AirQualityLevel.bad ||
      pm10Level == AirQualityLevel.veryBad;
}

enum AirQualityLevel { good, moderate, bad, veryBad }

enum TemperatureLevel { cold, cool, comfortable, warm, hot }

enum HumidityLevel { dry, comfortable, humid }
