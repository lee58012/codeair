import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class AppColors {
  // 브랜드
  static const Color primary    = Color(0xFF2563EB);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE2E8F0);

  // 텍스트
  static const Color textDark    = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color textLight   = Color(0xFF94A3B8);

  // 상태
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);

  // 센서 컬러
  static const Color pm25Color     = Color(0xFF6366F1); // indigo
  static const Color pm10Color     = Color(0xFF3B82F6); // blue
  static const Color tempColor     = Color(0xFFF97316); // orange
  static const Color humidityColor = Color(0xFF06B6D4); // cyan

  // 알람 로그 패널 (다크)
  static const Color logBackground = Color(0xFF1E293B);
  static const Color logText       = Color(0xFFCBD5E1);
  static const Color logBorder     = Color(0xFF334155);

  static const Color cardBackground = Color(0xFFFFFFFF);

  // 하위 호환
  static const Color textPrimary   = textDark;
  static const Color textSecondary = textMuted;
  static const Color accent        = primary;
  static const Color good          = success;
  static const Color bad           = danger;
  static const Color veryBad       = danger;

  static Color forAirQuality(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:     return success;
      case AirQualityLevel.moderate: return warning;
      case AirQualityLevel.bad:      return danger;
      case AirQualityLevel.veryBad:  return danger;
    }
  }

  static String labelForAirQuality(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:     return '좋음';
      case AirQualityLevel.moderate: return '보통';
      case AirQualityLevel.bad:      return '나쁨';
      case AirQualityLevel.veryBad:  return '매우 나쁨';
    }
  }
}
