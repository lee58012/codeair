import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../constants/app_colors.dart';

/// 디자인 참고: code-air AirChart
/// 흰 카드, 에어리어 차트, 그라디언트 fill
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
      default:            return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _getValue(e.value));
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$title History',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      '데이터 없음',
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _interval(),
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textDark,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final time = idx < history.length
                                ? DateFormat('HH:mm').format(history[idx].timestamp)
                                : '';
                            return LineTooltipItem(
                              '$time\n${s.y.toStringAsFixed(1)}',
                              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _interval() {
    if (history.isEmpty) return 10;
    final vals = history.map(_getValue).toList();
    final max = vals.reduce((a, b) => a > b ? a : b);
    if (max <= 10)  return 2;
    if (max <= 50)  return 10;
    if (max <= 100) return 20;
    return 50;
  }
}
