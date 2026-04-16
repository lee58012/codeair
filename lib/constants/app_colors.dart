import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class AppColors {
  // 브랜드 컬러
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF00BCD4);
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color cardBackground = Color(0xFF21262D);

  // 공기질 등급 컬러
  static const Color good = Color(0xFF4CAF50);
  static const Color moderate = Color(0xFFFFC107);
  static const Color bad = Color(0xFFFF5722);
  static const Color veryBad = Color(0xFFB71C1C);

  // 경보 컬러
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);

  // 센서별 컬러
  static const Color pm25Color = Color(0xFF7C4DFF);
  static const Color pm10Color = Color(0xFF00BCD4);
  static const Color tempColor = Color(0xFFFF7043);
  static const Color humidityColor = Color(0xFF26C6DA);

  // 텍스트
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);

  static Color forAirQuality(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return good;
      case AirQualityLevel.moderate:
        return moderate;
      case AirQualityLevel.bad:
        return bad;
      case AirQualityLevel.veryBad:
        return veryBad;
    }
  }

  static String labelForAirQuality(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return '좋음';
      case AirQualityLevel.moderate:
        return '보통';
      case AirQualityLevel.bad:
        return '나쁨';
      case AirQualityLevel.veryBad:
        return '매우 나쁨';
    }
  }
}
