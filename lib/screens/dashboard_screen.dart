import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../providers/alert_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_chart.dart';
import '../models/sensor_data.dart';
import '../models/alert_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Dashboard, 1 = Thresholds
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _activeTab == 0
                  ? _buildDashboardTab()
                  : _buildThresholdsTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header (sticky, white, border-bottom)
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final lastData = provider.latestData;
        final timeStr = lastData != null
            ? DateFormat('HH:mm:ss').format(lastData.timestamp)
            : '--:--:--';

        return Container(
          height: 70,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              // 브랜드
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'CODE AIR',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: '  | v2.0',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 마지막 업데이트 + 실시간 연결 뱃지
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '마지막 업데이트: $timeStr',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '실시간 연결됨',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // 탭 토글
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tabButton('Dashboard', 0),
                    _tabButton('Thresholds', 1),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 알림 아이콘
              Consumer<AlertProvider>(
                builder: (context, alertProvider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.textMuted,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/alerts'),
                      ),
                      if (alertProvider.unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
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
            ],
          ),
        );
      },
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dashboard Tab
  // ─────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () async => provider.sendDummyData(),
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                const Text(
                  '실시간 대기 질 지표',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 4 Metric Cards
                provider.isLoading && provider.latestData == null
                    ? _buildSkeletonRow()
                    : _buildMetricCards(provider),

                const SizedBox(height: 28),

                // Charts + Alert Log (responsive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 800) {
                      return _buildWideLayout(provider);
                    } else {
                      return _buildNarrowLayout(provider);
                    }
                  },
                ),

                const SizedBox(height: 32),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: const Text(
                    '© 2026 Code Air Inc. — IoT 공기질 모니터링 대시보드 v2.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonRow() {
    return Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
            child: const SensorCardSkeleton(),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards(SensorProvider provider) {
    final data = provider.latestData;

    if (data == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sensors_off, color: AppColors.textLight, size: 40),
            SizedBox(height: 10),
            Text('센서 데이터 없음',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            SizedBox(height: 4),
            Text('IoT 기기 연결을 확인해주세요',
                style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
        ),
      );
    }

    final cards = [
      SensorCard(
        title: 'PM 2.5',
        value: data.pm25,
        unit: 'µg/m³',
        accentColor: AppColors.pm25Color,
        icon: Icons.blur_on,
        isExceeded: data.pm25Level == AirQualityLevel.bad ||
            data.pm25Level == AirQualityLevel.veryBad,
      ),
      SensorCard(
        title: 'PM 10',
        value: data.pm10,
        unit: 'µg/m³',
        accentColor: AppColors.pm10Color,
        icon: Icons.grain,
        isExceeded: data.pm10Level == AirQualityLevel.bad ||
            data.pm10Level == AirQualityLevel.veryBad,
      ),
      SensorCard(
        title: 'Temperature',
        value: data.temperature,
        unit: '°C',
        accentColor: AppColors.tempColor,
        icon: Icons.thermostat,
        isExceeded: data.temperatureLevel == TemperatureLevel.hot,
      ),
      SensorCard(
        title: 'Humidity',
        value: data.humidity,
        unit: '%',
        accentColor: AppColors.humidityColor,
        icon: Icons.water_drop_outlined,
        isExceeded: data.humidityLevel == HumidityLevel.humid,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          // 가로로 4개
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: SizedBox(height: 160, child: cards[i])),
                if (i < cards.length - 1) const SizedBox(width: 14),
              ]
            ],
          );
        } else {
          // 2x2 그리드
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: cards,
          );
        }
      },
    );
  }

  // 넓은 화면: 차트(2/3) + 알림 로그(1/3) 나란히
  Widget _buildWideLayout(SensorProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildChartsSection(provider)),
        const SizedBox(width: 20),
        Expanded(flex: 1, child: _buildAlertLogSection()),
      ],
    );
  }

  // 좁은 화면: 차트 위, 알림 로그 아래
  Widget _buildNarrowLayout(SensorProvider provider) {
    return Column(
      children: [
        _buildChartsSection(provider),
        const SizedBox(height: 20),
        _buildAlertLogSection(),
      ],
    );
  }

  Widget _buildChartsSection(SensorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.refresh, color: AppColors.pm25Color, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Live Data Trends',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            AirChart(
              history: provider.history,
              metric: 'pm25',
              color: AppColors.pm25Color,
              title: 'PM 2.5',
            ),
            AirChart(
              history: provider.history,
              metric: 'pm10',
              color: AppColors.pm10Color,
              title: 'PM 10',
            ),
            AirChart(
              history: provider.history,
              metric: 'temperature',
              color: AppColors.tempColor,
              title: 'Temp',
            ),
            AirChart(
              history: provider.history,
              metric: 'humidity',
              color: AppColors.humidityColor,
              title: 'Humidity',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.notifications, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              '알람 로그 / 시스템 상태',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            return Container(
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 550),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.logBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: alertProvider.alerts.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '[SYSTEM INFO]',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '모든 센서 정상 작동 중...',
                          style: TextStyle(
                            color: AppColors.logText,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: alertProvider.alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alertProvider.alerts[index];
                        return _LogEntry(alert: alert);
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Thresholds Tab (기존 SettingsScreen 간소화)
  // ─────────────────────────────────────────────
  Widget _buildThresholdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THRESHOLD SETTINGS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '경보 발생 기준값 설정',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '자세한 설정은 설정 화면에서 변경할 수 있습니다.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/settings'),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('설정 화면 열기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 알람 로그 단일 항목
// ─────────────────────────────────────────────
class _LogEntry extends StatelessWidget {
  final AlertModel alert;
  const _LogEntry({required this.alert});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm').format(alert.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[$timeStr]',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                color: Color(0xFFF87171), // red-400
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
