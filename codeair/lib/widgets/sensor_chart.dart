import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../constants/app_colors.dart';

class SensorLineChart extends StatefulWidget {
  final List<SensorData> history;
  final String selectedMetric; // 'pm25', 'pm10', 'temperature', 'humidity'

  const SensorLineChart({
    super.key,
    required this.history,
    this.selectedMetric = 'pm25',
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart> {
  String _selectedMetric = 'pm25';

  final List<_MetricOption> _metrics = const [
    _MetricOption('pm25', 'PM2.5', AppColors.pm25Color),
    _MetricOption('pm10', 'PM10', AppColors.pm10Color),
    _MetricOption('temperature', '온도', AppColors.tempColor),
    _MetricOption('humidity', '습도', AppColors.humidityColor),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.selectedMetric;
  }

  double _getValue(SensorData d) {
    switch (_selectedMetric) {
      case 'pm25':
        return d.pm25;
      case 'pm10':
        return d.pm10;
      case 'temperature':
        return d.temperature;
      case 'humidity':
        return d.humidity;
      default:
        return d.pm25;
    }
  }

  Color get _metricColor {
    return _metrics.firstWhere((m) => m.key == _selectedMetric).color;
  }

  String get _unit {
    switch (_selectedMetric) {
      case 'pm25':
      case 'pm10':
        return 'µg/m³';
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '시간별 추이',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '최근 24회 측정',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 메트릭 선택 탭
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _metrics.map((m) {
                final isSelected = m.key == _selectedMetric;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMetric = m.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? m.color.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? m.color : Colors.white24,
                        ),
                      ),
                      child: Text(
                        m.label,
                        style: TextStyle(
                          color: isSelected ? m.color : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 차트
          if (widget.history.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  '데이터가 없습니다',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getInterval(),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (widget.history.length / 4).ceilToDouble(),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= widget.history.length) {
                            return const SizedBox();
                          }
                          return Text(
                            DateFormat('HH:mm').format(widget.history[idx].timestamp),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.history.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), _getValue(e.value));
                      }).toList(),
                      isCurved: true,
                      color: _metricColor,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: widget.history.length <= 12,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 3,
                          color: _metricColor,
                          strokeWidth: 1.5,
                          strokeColor: AppColors.cardBackground,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _metricColor.withOpacity(0.25),
                            _metricColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surface,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final time = idx < widget.history.length
                            ? DateFormat('HH:mm').format(widget.history[idx].timestamp)
                            : '';
                        return LineTooltipItem(
                          '$time\n${s.y.toStringAsFixed(1)} $_unit',
                          TextStyle(
                            color: _metricColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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

  double _getInterval() {
    if (widget.history.isEmpty) return 10;
    final values = widget.history.map(_getValue).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 10) return 2;
    if (max <= 50) return 10;
    if (max <= 100) return 20;
    return 50;
  }
}

class _MetricOption {
  final String key;
  final String label;
  final Color color;
  const _MetricOption(this.key, this.label, this.color);
}
