import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../constants/app_colors.dart';

/// 디자인 참고: code-air ChartCard (미니멀 스파크라인)
/// 흰 카드 + 제목(좌) + 현재값(우) + 스파크라인 + 그라디언트 fill
class AirChart extends StatelessWidget {
  final List<SensorData> history;
  final String metric; // 'pm25' | 'pm10' | 'temperature' | 'humidity'
  final Color color;
  final String title;

  const AirChart({
    super.key,
    required this.history,
    required this.metric,
    required this.color,
    required this.title,
  });

  double _getValue(SensorData d) {
    switch (metric) {
      case 'pm25':        return d.pm25;
      case 'pm10':        return d.pm10;
      case 'temperature': return d.temperature;
      case 'humidity':    return d.humidity;
      case 'co2':         return d.co2;
      default:            return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _getValue(e.value));
    }).toList();

    final current = history.isNotEmpty ? _getValue(history.last) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 제목 (좌) + 현재값 (우)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                current.toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 스파크라인
          Expanded(
            child: history.length < 2
                ? Center(
                    child: Text(
                      history.isEmpty ? '데이터 없음' : '--',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textDark,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final time = idx >= 0 && idx < history.length
                                ? DateFormat('HH:mm:ss').format(history[idx].timestamp)
                                : '';
                            return LineTooltipItem(
                              '$time\n${spot.y.toStringAsFixed(1)}',
                              TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            );
                          }).toList(),
                        ),
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((_) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: color.withValues(alpha: 0.3),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: color,
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.25,
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
          ),
        ],
      ),
    );
  }
}
