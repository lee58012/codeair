import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/sensor_scale.dart';
import '../models/sensor_data.dart';

/// 오늘의 통계 표 — 각 센서별 평균/최고 + 시스템 상태
class TodaySummary extends StatelessWidget {
  final List<SensorData> history;
  final int alertsToday;

  const TodaySummary({
    super.key,
    required this.history,
    this.alertsToday = 0,
  });

  ({double avg, double peak, double low}) _stats(double Function(SensorData) read) {
    if (history.isEmpty) return (avg: 0, peak: 0, low: 0);
    final vals = history.map(read).toList();
    return (
      avg: vals.reduce((a, b) => a + b) / vals.length,
      peak: vals.reduce((a, b) => a > b ? a : b),
      low: vals.reduce((a, b) => a < b ? a : b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pm25 = _stats((d) => d.pm25);
    final pm10 = _stats((d) => d.pm10);
    final co2 = _stats((d) => d.co2);
    final temp = _stats((d) => d.temperature);
    final hum = _stats((d) => d.humidity);

    final rows = <_SummaryRow>[
      _SummaryRow('PM2.5 평균', '초미세먼지',
          '${pm25.avg.toStringAsFixed(1)} µg/m³',
          SensorScales.pm25.tierOf(pm25.avg), SensorScales.pm25.color),
      _SummaryRow('PM2.5 최고', '초미세먼지',
          '${pm25.peak.toStringAsFixed(1)} µg/m³',
          SensorScales.pm25.tierOf(pm25.peak), SensorScales.pm25.color),
      _SummaryRow('PM10 평균', '미세먼지',
          '${pm10.avg.toStringAsFixed(1)} µg/m³',
          SensorScales.pm10.tierOf(pm10.avg), SensorScales.pm10.color),
      _SummaryRow('PM10 최고', '미세먼지',
          '${pm10.peak.toStringAsFixed(1)} µg/m³',
          SensorScales.pm10.tierOf(pm10.peak), SensorScales.pm10.color),
      _SummaryRow('CO₂ 평균', '이산화탄소',
          '${co2.avg.toStringAsFixed(0)} ppm',
          SensorScales.co2.tierOf(co2.avg), SensorScales.co2.color),
      _SummaryRow('CO₂ 최고', '이산화탄소',
          '${co2.peak.toStringAsFixed(0)} ppm',
          SensorScales.co2.tierOf(co2.peak), SensorScales.co2.color),
      _SummaryRow('기온 범위', '온도',
          '${temp.low.toStringAsFixed(1)}–${temp.peak.toStringAsFixed(1)}°C',
          SensorTier.good, SensorScales.temp.color),
      _SummaryRow('습도 범위', '습도',
          '${hum.low.toStringAsFixed(0)}–${hum.peak.toStringAsFixed(0)}%',
          SensorTier.good, SensorScales.hum.color),
      _SummaryRow('경보 총계', '시스템', '$alertsToday회',
          alertsToday > 0 ? SensorTier.bad : SensorTier.good,
          alertsToday > 0 ? AppColors.tierBad : AppColors.tierGood),
    ];

    final today = DateFormat('yyyy.MM.dd').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              'TODAY · $today',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.textLight,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: r.sensorColor, width: 3),
                      bottom: i < rows.length - 1
                          ? const BorderSide(color: AppColors.border)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              r.sub,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _tierBadge(r.value, r.tier),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(String value, SensorTier tier) {
    final color = SensorScales.colorForTier(tier);
    final bg = switch (tier) {
      SensorTier.good => const Color(0xFFF0FDF4),
      SensorTier.moderate => const Color(0xFFFFFBEB),
      SensorTier.bad => const Color(0xFFFFF1F2),
      SensorTier.critical => const Color(0xFFFFE4E6),
      _ => const Color(0xFFF8FAFC),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String sub;
  final String value;
  final SensorTier tier;
  final Color sensorColor;
  _SummaryRow(this.label, this.sub, this.value, this.tier, this.sensorColor);
}
