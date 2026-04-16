import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../providers/alert_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/sensor_card.dart';
import '../models/sensor_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<SensorProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: () async => provider.sendDummyData(),
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ──
                  SliverAppBar(
                    backgroundColor: AppColors.background,
                    floating: true,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.air,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CodeAir',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '기기: ${provider.deviceId}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      // 경보 뱃지
                      Consumer<AlertProvider>(
                        builder: (context, alertProvider, _) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.notifications_outlined),
                                color: AppColors.textPrimary,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/alerts'),
                              ),
                              if (alertProvider.unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${alertProvider.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        color: AppColors.textPrimary,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── 마지막 업데이트 ──
                        if (provider.latestData != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.good,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '마지막 업데이트: ${DateFormat('yyyy.MM.dd HH:mm:ss').format(provider.latestData!.timestamp)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ── 경보 배너 ──
                        if (provider.latestData?.hasAlert == true)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.danger),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    '미세먼지 수치가 기준치를 초과했습니다!',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/alerts'),
                                  child: const Text('자세히',
                                      style: TextStyle(
                                          color: AppColors.danger)),
                                ),
                              ],
                            ),
                          ),

                        // ── 센서 카드 그리드 (차트 포함) ──
                        provider.isLoading && provider.latestData == null
                            ? _buildSkeletonGrid()
                            : _buildSensorGrid(provider),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: List.generate(4, (_) => const SensorCardSkeleton()),
    );
  }

  Widget _buildSensorGrid(SensorProvider provider) {
    final data = provider.latestData;

    if (data == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sensors_off,
                color: AppColors.textSecondary, size: 48),
            SizedBox(height: 12),
            Text('센서 데이터 없음',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('IoT 기기 연결을 확인해주세요',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: [
        SensorCard(
          title: 'PM2.5 (초미세먼지)',
          value: data.pm25.toStringAsFixed(1),
          unit: 'µg/m³',
          statusLabel: AppColors.labelForAirQuality(data.pm25Level),
          statusColor: AppColors.forAirQuality(data.pm25Level),
          accentColor: AppColors.pm25Color,
          icon: Icons.blur_on,
          metricKey: 'pm25',
          history: provider.history,
          hasAlert: data.pm25Level == AirQualityLevel.bad ||
              data.pm25Level == AirQualityLevel.veryBad,
        ),
        SensorCard(
          title: 'PM10 (미세먼지)',
          value: data.pm10.toStringAsFixed(1),
          unit: 'µg/m³',
          statusLabel: AppColors.labelForAirQuality(data.pm10Level),
          statusColor: AppColors.forAirQuality(data.pm10Level),
          accentColor: AppColors.pm10Color,
          icon: Icons.grain,
          metricKey: 'pm10',
          history: provider.history,
          hasAlert: data.pm10Level == AirQualityLevel.bad ||
              data.pm10Level == AirQualityLevel.veryBad,
        ),
        SensorCard(
          title: '온도',
          value: data.temperature.toStringAsFixed(1),
          unit: '°C',
          statusLabel: _tempLabel(data.temperatureLevel),
          statusColor: AppColors.tempColor,
          accentColor: AppColors.tempColor,
          icon: Icons.thermostat,
          metricKey: 'temperature',
          history: provider.history,
        ),
        SensorCard(
          title: '습도',
          value: data.humidity.toStringAsFixed(1),
          unit: '%',
          statusLabel: _humidityLabel(data.humidityLevel),
          statusColor: AppColors.humidityColor,
          accentColor: AppColors.humidityColor,
          icon: Icons.water_drop_outlined,
          metricKey: 'humidity',
          history: provider.history,
        ),
      ],
    );
  }

  String _tempLabel(TemperatureLevel level) {
    switch (level) {
      case TemperatureLevel.cold:        return '매우 추움';
      case TemperatureLevel.cool:        return '서늘함';
      case TemperatureLevel.comfortable: return '쾌적';
      case TemperatureLevel.warm:        return '따뜻함';
      case TemperatureLevel.hot:         return '더움';
    }
  }

  String _humidityLabel(HumidityLevel level) {
    switch (level) {
      case HumidityLevel.dry:         return '건조';
      case HumidityLevel.comfortable: return '쾌적';
      case HumidityLevel.humid:       return '습함';
    }
  }
}
