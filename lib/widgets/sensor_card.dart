import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../models/sensor_data.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String statusLabel;
  final Color statusColor;
  final Color accentColor;
  final IconData icon;
  final bool hasAlert;
  final List<SensorData> history;
  final String metricKey; // 'pm25' | 'pm10' | 'temperature' | 'humidity'

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.statusLabel,
    required this.statusColor,
    required this.accentColor,
    required this.icon,
    required this.metricKey,
    this.hasAlert = false,
    this.history = const [],
  });

  double _getValue(SensorData d) {
    switch (metricKey) {
      case 'pm25':        return d.pm25;
      case 'pm10':        return d.pm10;
      case 'temperature': return d.temperature;
      case 'humidity':    return d.humidity;
      default:            return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlert
              ? AppColors.danger.withValues(alpha: 0.6)
              : accentColor.withValues(alpha: 0.2),
          width: hasAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더: 아이콘 + 제목 + 경보 뱃지 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (hasAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 11),
                      SizedBox(width: 3),
                      Text(
                        '경보',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 수치 + 단위 ──
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── 상태 뱃지 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── 미니 스파크라인 차트 ──
          _MiniSparkline(
            history: history,
            getValue: _getValue,
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

/// 카드 내부 소형 라인 차트 (축/레이블 없음)
class _MiniSparkline extends StatelessWidget {
  final List<SensorData> history;
  final double Function(SensorData) getValue;
  final Color color;

  const _MiniSparkline({
    required this.history,
    required this.getValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            '데이터 없음',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    return SizedBox(
      height: 50,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로딩 중 스켈레톤 카드
class SensorCardSkeleton extends StatelessWidget {
  const SensorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _shimmer(34, 34, radius: 9),
            const SizedBox(width: 8),
            _shimmer(80, 12),
          ]),
          const SizedBox(height: 12),
          _shimmer(90, 28),
          const SizedBox(height: 6),
          _shimmer(55, 22, radius: 20),
          const SizedBox(height: 10),
          _shimmer(double.infinity, 50),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
