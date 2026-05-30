import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/sensor_scale.dart';
import '../models/sensor_data.dart';
import 'aqi_bar.dart';

/// Hero — 좌측 큰 패널. 큰 숫자 + 상태 배너 + AQI 바 + 24h 통계
class HeroPanel extends StatelessWidget {
  final SensorScale scale;
  final double? value;
  final List<SensorData> history;
  final VoidCallback? onTap;

  const HeroPanel({
    super.key,
    required this.scale,
    required this.value,
    required this.history,
    this.onTap,
  });

  double _readMetric(SensorData d) {
    switch (scale.key) {
      case 'pm25': return d.pm25;
      case 'pm10': return d.pm10;
      case 'temp': return d.temperature;
      case 'hum':  return d.humidity;
      case 'co2':  return d.co2;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    final tier = scale.tierOf(v);
    final tierColor = SensorScales.colorForTier(tier);

    // 24h 통계
    double? avg, peak, mn;
    if (history.isNotEmpty) {
      final vals = history.map(_readMetric).toList();
      avg = vals.reduce((a, b) => a + b) / vals.length;
      peak = vals.reduce((a, b) => a > b ? a : b);
      mn = vals.reduce((a, b) => a < b ? a : b);
    }

    // delta (첫 값 대비)
    double? delta;
    if (history.isNotEmpty && v != null) {
      delta = v - _readMetric(history.first);
    }

    final chipBg = switch (tier) {
      SensorTier.good => const Color(0xFFDCFCE7),
      SensorTier.moderate => const Color(0xFFFEF3C7),
      SensorTier.bad => const Color(0xFFFEE2E2),
      SensorTier.critical => const Color(0xFF7F1D1D),
      _ => const Color(0xFFF1F5F9),
    };
    final chipFg = switch (tier) {
      SensorTier.good => const Color(0xFF166534),
      SensorTier.moderate => const Color(0xFF92400E),
      SensorTier.bad => const Color(0xFF991B1B),
      SensorTier.critical => const Color(0xFFFEF2F2),
      _ => AppColors.textMuted,
    };

    final messages = _statusMessage(scale.key, tier);

    final bannerBg = switch (tier) {
      SensorTier.good => const Color(0xFFF0FDF4),
      SensorTier.moderate => const Color(0xFFFFFBEB),
      SensorTier.bad => const Color(0xFFFFF1F2),
      SensorTier.critical => const Color(0xFF450A0A),
      _ => AppColors.surface,
    };
    final bannerBdr = switch (tier) {
      SensorTier.good => const Color(0xFF86EFAC),
      SensorTier.moderate => const Color(0xFFFCD34D),
      SensorTier.bad => const Color(0xFFFECDD3),
      SensorTier.critical => const Color(0xFF7F1D1D),
      _ => AppColors.border,
    };
    final bannerHl = switch (tier) {
      SensorTier.good => const Color(0xFF15803D),
      SensorTier.moderate => const Color(0xFFB45309),
      SensorTier.bad => const Color(0xFFBE123C),
      SensorTier.critical => const Color(0xFFFEF2F2),
      _ => AppColors.textDark,
    };
    final bannerSub = switch (tier) {
      SensorTier.good => const Color(0xFF166534),
      SensorTier.moderate => const Color(0xFF92400E),
      SensorTier.bad => const Color(0xFF9F1239),
      SensorTier.critical => const Color(0xFFFCA5A5),
      _ => AppColors.textMuted,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 라벨 + tier chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRIMARY METRIC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            color: AppColors.textLight,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: scale.code,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextSpan(
                                text: ' · ${scale.name}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scale.tierLabel(tier),
                      style: TextStyle(
                        color: chipFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 큰 숫자
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    v?.toStringAsFixed(1) ?? '--',
                    style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -4,
                      color: AppColors.textDark,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      scale.unit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // delta
              if (delta != null)
                Row(
                  children: [
                    Icon(
                      delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: delta >= 0 ? AppColors.tierBad : AppColors.tierGood,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} ${scale.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: delta >= 0 ? AppColors.tierBad : AppColors.tierGood,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '24h 이전 대비',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // 상태 배너
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: bannerBg,
                  border: Border.all(color: bannerBdr),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: tierColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messages.$1,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: bannerHl,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            messages.$2,
                            style: TextStyle(
                              fontSize: 13,
                              color: bannerSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // AQI 척도
              const Text(
                '기준 척도',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),
              AqiBar(scale: scale, value: v),
              const SizedBox(height: 24),

              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 24),

              // 24h 통계
              if (avg != null && peak != null && mn != null)
                Row(
                  children: [
                    Expanded(child: _statBox('24H 최고', peak.toStringAsFixed(1), scale.unit, true)),
                    Expanded(child: _statBox('24H 평균', avg.toStringAsFixed(1), scale.unit, true)),
                    Expanded(child: _statBox('24H 최저', mn.toStringAsFixed(1), scale.unit, false)),
                  ],
                ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // 차트 힌트
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, size: 12, color: Color(0xFF94A3B8)),
                      SizedBox(width: 7),
                      Text(
                        '클릭하여 24시간 추이 보기',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF1F5F9),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, String unit, bool rightBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: rightBorder
            ? const Border(right: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  /// (헤드라인, 액션) 상태 메시지
  (String, String) _statusMessage(String key, SensorTier tier) {
    final map = {
      'pm25': {
        SensorTier.good: ('안전 상태', '실내 공기질이 쾌적합니다'),
        SensorTier.moderate: ('환기 권장', '창문을 10분 이상 개방해 환기하세요'),
        SensorTier.bad: ('환기 필요', '즉시 창문을 열고 공기청정기를 가동하세요'),
        SensorTier.critical: ('즉시 환기', '모든 창문 개방 후 공기청정기 최대 가동하세요'),
      },
      'pm10': {
        SensorTier.good: ('안전 상태', '실내 공기질이 쾌적합니다'),
        SensorTier.moderate: ('환기 권장', '창문을 열어 실내 공기를 순환시키세요'),
        SensorTier.bad: ('환기 필요', '즉시 창문을 개방하고 환기하세요'),
        SensorTier.critical: ('즉시 환기', '창문 전체 개방 및 공기청정기 가동하세요'),
      },
      'temp': {
        SensorTier.good: ('쾌적한 실내 온도', '적정 실내 온도가 유지되고 있습니다'),
        SensorTier.moderate: ('온도 조절 권장', '냉난방기로 실내 온도를 조절하세요'),
        SensorTier.bad: ('온도 경고', '냉난방기를 가동해 온도를 적정 범위로 맞추세요'),
        SensorTier.critical: ('온도 위험', '즉시 냉난방 조치 및 창문 개폐를 확인하세요'),
      },
      'hum': {
        SensorTier.good: ('쾌적한 습도', '적정 실내 습도가 유지되고 있습니다'),
        SensorTier.moderate: ('습도 조절 권장', '가습기 또는 제습기 사용을 권장합니다'),
        SensorTier.bad: ('습도 경고', '환기 또는 제습 조치가 필요합니다'),
        SensorTier.critical: ('습도 위험', '즉시 환기/제습 조치가 필요합니다'),
      },
      'co2': {
        SensorTier.good: ('실내 공기 일상', 'CO₂ 농도가 적정하여 쾌적한 실내입니다'),
        SensorTier.moderate: ('환기 권장', '창문을 열어 CO₂를 낮춰주세요'),
        SensorTier.bad: ('환기 필요', '즉시 창문 개방 후 5분 이상 환기하세요'),
        SensorTier.critical: ('CO₂ 위험 수준', '즉시 모든 창문을 열고 실내를 완전히 환기하세요'),
      },
    };
    return map[key]?[tier] ?? ('정보 없음', '데이터 대기 중');
  }
}
