import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 디자인 시스템의 sensor scale (좋음/보통/나쁨/매우나쁨/위험)
class ScaleTier {
  final double at;
  final String label;
  const ScaleTier(this.at, this.label);
}

enum SensorTier { good, moderate, bad, critical, none }

class SensorScale {
  final String key;
  final String code; // 표시용 코드 (PM2.5, CO2 등)
  final String name; // 한글 풀네임
  final String unit;
  final Color color;
  final List<ScaleTier> ticks; // AQI bar 눈금
  // [good, moderate, bad, crit] 범위 (min, max)
  final List<double> good;
  final List<double> moderate;
  final List<double> bad;
  final List<double> critical;

  const SensorScale({
    required this.key,
    required this.code,
    required this.name,
    required this.unit,
    required this.color,
    required this.ticks,
    required this.good,
    required this.moderate,
    required this.bad,
    required this.critical,
  });

  double get scaleMax => ticks.last.at;

  /// 현재값으로 tier 판정
  SensorTier tierOf(double? v) {
    if (v == null) return SensorTier.none;
    // 온도/습도는 양방향 범위
    if (key == 'temp' || key == 'hum') {
      if (v >= good[0] && v <= good[1]) return SensorTier.good;
      if (v >= moderate[0] && v <= moderate[1]) return SensorTier.moderate;
      if (v < bad[0] || v > bad[1]) return SensorTier.critical;
      return SensorTier.bad;
    }
    // 단방향(상한)
    if (v < moderate[0]) return SensorTier.good;
    if (v < bad[0]) return SensorTier.moderate;
    if (v < critical[0]) return SensorTier.bad;
    return SensorTier.critical;
  }

  String tierLabel(SensorTier t) {
    if (key == 'temp' || key == 'hum') {
      switch (t) {
        case SensorTier.good: return '적정';
        case SensorTier.moderate: return '보통';
        case SensorTier.bad: return '경고';
        case SensorTier.critical: return '경보';
        case SensorTier.none: return '—';
      }
    }
    switch (t) {
      case SensorTier.good: return '좋음';
      case SensorTier.moderate: return '보통';
      case SensorTier.bad: return '나쁨';
      case SensorTier.critical: return '매우나쁨';
      case SensorTier.none: return '—';
    }
  }
}

/// 모든 센서 정의 (디자인 dashboard-shared.jsx에서 가져옴)
class SensorScales {
  static const pm25 = SensorScale(
    key: 'pm25', code: 'PM2.5', name: '초미세먼지', unit: 'µg/m³',
    color: AppColors.pm25Color,
    ticks: [
      ScaleTier(0, '좋음'), ScaleTier(15, '보통'), ScaleTier(35, '나쁨'),
      ScaleTier(75, '매우나쁨'), ScaleTier(150, '위험'),
    ],
    good: [0, 15], moderate: [15, 35], bad: [35, 75], critical: [75, 300],
  );

  static const pm10 = SensorScale(
    key: 'pm10', code: 'PM10', name: '미세먼지', unit: 'µg/m³',
    color: AppColors.pm10Color,
    ticks: [
      ScaleTier(0, '좋음'), ScaleTier(30, '보통'), ScaleTier(80, '나쁨'),
      ScaleTier(150, '매우나쁨'), ScaleTier(300, '위험'),
    ],
    good: [0, 30], moderate: [30, 80], bad: [80, 150], critical: [150, 600],
  );

  static const temp = SensorScale(
    key: 'temp', code: 'TEMP', name: '온도', unit: '°C',
    color: AppColors.tempColor,
    ticks: [
      ScaleTier(-10, '한랭'), ScaleTier(0, '저온'), ScaleTier(18, '쾌적'),
      ScaleTier(28, '더움'), ScaleTier(35, '고온'),
    ],
    good: [18, 28], moderate: [10, 35], bad: [-10, 40], critical: [-20, 50],
  );

  static const hum = SensorScale(
    key: 'hum', code: 'HUM', name: '습도', unit: '%',
    color: AppColors.humidityColor,
    ticks: [
      ScaleTier(0, '건조'), ScaleTier(30, '쾌적'), ScaleTier(60, '습함'),
      ScaleTier(80, '매우습함'),
    ],
    good: [30, 60], moderate: [20, 75], bad: [10, 90], critical: [0, 100],
  );

  static const co2 = SensorScale(
    key: 'co2', code: 'CO2', name: '이산화탄소', unit: 'ppm',
    color: Color(0xFF7C3AED),
    ticks: [
      ScaleTier(400, '적정'), ScaleTier(800, '보통'),
      ScaleTier(1500, '나쁨'), ScaleTier(2500, '매우나쁨'),
    ],
    good: [0, 800], moderate: [800, 1500], bad: [1500, 2500], critical: [2500, 5000],
  );

  static const all = [pm25, pm10, co2, temp, hum];

  static SensorScale byKey(String key) {
    return all.firstWhere((s) => s.key == key, orElse: () => pm25);
  }

  /// tier별 강조 색상
  static Color colorForTier(SensorTier t) {
    switch (t) {
      case SensorTier.good: return AppColors.tierGood;
      case SensorTier.moderate: return AppColors.tierMod;
      case SensorTier.bad: return AppColors.tierBad;
      case SensorTier.critical: return AppColors.tierCrit;
      case SensorTier.none: return AppColors.textMuted;
    }
  }

  /// AQI bar 그라디언트 (디자인 그대로)
  static List<Color> gradientFor(String key) {
    switch (key) {
      case 'pm25':
        return const [
          Color(0xFF16A34A), Color(0xFF16A34A), Color(0xFFD97706),
          Color(0xFFDC2626), Color(0xFF7F1D1D),
        ];
      case 'pm10':
        return const [
          Color(0xFF16A34A), Color(0xFFD97706), Color(0xFFDC2626),
          Color(0xFF7F1D1D),
        ];
      case 'temp':
        return const [
          Color(0xFF0891B2), Color(0xFF16A34A), Color(0xFFD97706),
          Color(0xFFDC2626),
        ];
      case 'hum':
        return const [
          Color(0xFFD97706), Color(0xFF16A34A), Color(0xFF16A34A),
          Color(0xFF0891B2), Color(0xFF1E40AF),
        ];
      case 'co2':
        return const [
          Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF16A34A),
          Color(0xFFD97706), Color(0xFFDC2626), Color(0xFF7F1D1D),
        ];
      default:
        return const [Color(0xFFE2E8F0), Color(0xFFE2E8F0)];
    }
  }

  static List<double> gradientStopsFor(String key) {
    switch (key) {
      case 'pm25': return const [0.0, 0.10, 0.22, 0.48, 1.0];
      case 'pm10': return const [0.0, 0.28, 0.54, 1.0];
      case 'temp': return const [0.0, 0.35, 0.60, 0.90];
      case 'hum':  return const [0.0, 0.28, 0.56, 0.75, 1.0];
      case 'co2':  return const [0.0, 0.08, 0.16, 0.30, 0.60, 1.0];
      default: return const [0.0, 1.0];
    }
  }
}
