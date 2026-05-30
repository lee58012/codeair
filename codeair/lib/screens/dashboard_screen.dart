import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../providers/alert_provider.dart';
import '../constants/app_colors.dart';
import '../constants/sensor_scale.dart';
import '../widgets/sensor_chart.dart';
import '../widgets/hero_panel.dart';
import '../widgets/secondary_rail.dart';
import '../widgets/terminal_log.dart';
import '../widgets/today_summary.dart';
import '../models/alert_model.dart';
import '../screens/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Dashboard, 1 = Thresholds
  int _activeTab = 0;

  // Hero에 표시할 센서 키
  String _heroKey = 'pm25';

  // 새 경보 토스트용
  AlertProvider? _alertProvider;
  String? _lastAlertId;

  // 실시간 연결 상태
  bool _fbConnected = false;
  StreamSubscription? _connectedSub;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();

    // Firebase 연결 상태 구독
    _connectedSub = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) {
      if (!mounted) return;
      setState(() => _fbConnected = event.snapshot.value == true);
    });

    // 5초마다 데이터 신선도 재평가 (UI 갱신)
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alertProvider = context.read<AlertProvider>();
      // 앱 진입 시점의 최신 경보를 베이스라인으로 저장(기존 경보는 토스트 안 띄움)
      if (_alertProvider!.alerts.isNotEmpty) {
        _lastAlertId = _alertProvider!.alerts.first.id;
      }
      _alertProvider!.addListener(_onAlertsChanged);
    });
  }

  void _onAlertsChanged() {
    final ap = _alertProvider;
    if (ap == null || ap.alerts.isEmpty) return;
    final latest = ap.alerts.first;
    if (_lastAlertId == null) {
      _lastAlertId = latest.id;
      return;
    }
    if (latest.id != _lastAlertId) {
      _lastAlertId = latest.id;
      // 주의·위험 경보만 토스트 표시 (INFO·PUSH 시스템 로그 제외)
      if (latest.severity == AlertSeverity.warning ||
          latest.severity == AlertSeverity.danger) {
        _showTopAlert(latest);
      }
    }
  }

  void _showTopAlert(AlertModel alert) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopAlertToast(
        alert: alert,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _alertProvider?.removeListener(_onAlertsChanged);
    _connectedSub?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }

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

        final narrow = MediaQuery.of(context).size.width < 600;

        // ── 재사용 위젯 ──
        final brand = MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _activeTab = 0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'CODE AIR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: narrow ? 19 : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: '  | v1.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: narrow ? 13 : 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final toggle = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tabButton('Dashboard', 0),
              _tabButton('Thresholds', 1),
            ],
          ),
        );

        final bell = Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppColors.textMuted,
                  onPressed: () => showNotificationDrawer(context),
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
        );

        final decoration = const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        );

        // ── 좁은 화면(모바일): 2줄로 분리해 잘림 방지 ──
        if (narrow) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
            decoration: decoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: brand),
                    const Spacer(),
                    _buildConnectionPill(lastData),
                    bell,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    toggle,
                    const Spacer(),
                    Text(
                      '업데이트 $timeStr',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // ── 넓은 화면(웹/태블릿): 기존 단일 행 ──
        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: decoration,
          child: Row(
            children: [
              brand,
              const Spacer(),
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
                  _buildConnectionPill(lastData),
                ],
              ),
              const SizedBox(width: 20),
              toggle,
              const SizedBox(width: 16),
              bell,
            ],
          ),
        );
      },
    );
  }

  /// 실시간 연결 뱃지 — Firebase 연결 + 데이터 신선도 둘 다 확인
  Widget _buildConnectionPill(dynamic lastData) {
    final isFresh = lastData != null &&
        DateTime.now().difference(lastData.timestamp).inSeconds < 60;
    final isConnected = _fbConnected && isFresh;

    final bg = isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final dot = isConnected ? AppColors.success : AppColors.danger;
    final txt = isConnected ? const Color(0xFF166534) : const Color(0xFF991B1B);
    final label = isConnected
        ? '실시간 연결됨'
        : (!_fbConnected ? '네트워크 끊김' : '데이터 수신 대기');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: txt,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _activeTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // 스위치처럼 동작 — 어느 쪽을 눌러도 반대 탭으로 토글
        onTap: () => setState(() => _activeTab = _activeTab == 0 ? 1 : 0),
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
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dashboard Tab
  // ─────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final data = provider.latestData;
        final values = <String, double?>{
          'pm25': data?.pm25,
          'pm10': data?.pm10,
          'temp': data?.temperature,
          'hum':  data?.humidity,
          'co2':  data?.co2,
        };
        final heroScale = SensorScales.byKey(_heroKey);
        final heroVal = values[_heroKey];

        return RefreshIndicator(
          onRefresh: () async => provider.refresh(),
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Hero + Secondary Rail
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 30,
                              child: HeroPanel(
                                scale: heroScale,
                                value: heroVal,
                                history: provider.history,
                                onTap: () => _showChartForKey(_heroKey),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 13,
                              child: Consumer<AlertProvider>(
                                builder: (context, alertProv, _) {
                                  return SecondaryRail(
                                    heroKey: _heroKey,
                                    values: values,
                                    onSelect: (k) => setState(() => _heroKey = k),
                                    totalAlertsToday: alertProv.alerts.length,
                                    alertCount: alertProv.unreadCount,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      HeroPanel(
                        scale: heroScale,
                        value: heroVal,
                        history: provider.history,
                        onTap: () => _showChartForKey(_heroKey),
                      ),
                      const SizedBox(height: 14),
                      Consumer<AlertProvider>(
                        builder: (context, alertProv, _) {
                          return SecondaryRail(
                            heroKey: _heroKey,
                            values: values,
                            onSelect: (k) => setState(() => _heroKey = k),
                            totalAlertsToday: alertProv.alerts.length,
                            alertCount: alertProv.unreadCount,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Row 2: Terminal Log + Today Summary
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 30,
                              child: Consumer<AlertProvider>(
                                builder: (context, alertProv, _) {
                                  return TerminalLog(alerts: alertProv.alerts);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 13,
                              child: Consumer<AlertProvider>(
                                builder: (context, alertProv, _) {
                                  return TodaySummary(
                                    history: provider.history,
                                    alertsToday: alertProv.alerts.length,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Consumer<AlertProvider>(
                        builder: (context, alertProv, _) {
                          return TerminalLog(alerts: alertProv.alerts);
                        },
                      ),
                      const SizedBox(height: 14),
                      Consumer<AlertProvider>(
                        builder: (context, alertProv, _) {
                          return TodaySummary(
                            history: provider.history,
                            alertsToday: alertProv.alerts.length,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Footer
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '© 2026 Code Air Inc. · IoT 공기질 모니터링 대시보드 v1.0',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Hero/Rail에서 센서 키로 차트 모달 띄우기
  void _showChartForKey(String key) {
    final scale = SensorScales.byKey(key);
    final metric =
        key == 'temp' ? 'temperature' : (key == 'hum' ? 'humidity' : key);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer<SensorProvider>(
        builder: (context, provider, _) {
          final history = provider.history;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${scale.name} (${scale.code})',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        child: SizedBox(
                          height: 320,
                          child: AirChart(
                            history: history,
                            metric: metric,
                            color: scale.color,
                            title: '${scale.name} (${scale.code})',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Thresholds Tab — 경보 기준값 카드형 표시
  // ─────────────────────────────────────────────
  Widget _buildThresholdsTab() {
    const sensors = [
      _SensorThreshold(
        key: 'pm25', code: 'PM2.5', label: 'PM2.5 · 초미세먼지', unit: 'µg/m³',
        color: AppColors.pm25Color,
        levels: [
          _ThresholdLevel('좋음',   Color(0xFF16A34A), Color(0xFFF0FDF4), '0 – 15',   '일반인도 안심'),
          _ThresholdLevel('보통',   Color(0xFFD97706), Color(0xFFFFFBEB), '15 – 35',  '민감군 주의'),
          _ThresholdLevel('나쁨',   Color(0xFFDC2626), Color(0xFFFFF1F2), '35 – 75',  '환기 필요'),
          _ThresholdLevel('매우나쁨', Color(0xFF9F1239), Color(0xFFFFE4E6), '75 이상',  '즉시 환기·공기청정기 가동'),
        ],
      ),
      _SensorThreshold(
        key: 'pm10', code: 'PM10', label: 'PM10 · 미세먼지', unit: 'µg/m³',
        color: AppColors.pm10Color,
        levels: [
          _ThresholdLevel('좋음',   Color(0xFF16A34A), Color(0xFFF0FDF4), '0 – 30',    '일반인도 안심'),
          _ThresholdLevel('보통',   Color(0xFFD97706), Color(0xFFFFFBEB), '30 – 80',   '민감군 주의'),
          _ThresholdLevel('나쁨',   Color(0xFFDC2626), Color(0xFFFFF1F2), '80 – 150',  '환기 필요'),
          _ThresholdLevel('매우나쁨', Color(0xFF9F1239), Color(0xFFFFE4E6), '150 이상',  '즉시 환기·공기청정기 가동'),
        ],
      ),
      _SensorThreshold(
        key: 'co2', code: 'CO2', label: 'CO2 · 이산화탄소', unit: 'ppm',
        color: AppColors.co2Color,
        levels: [
          _ThresholdLevel('좋음',   Color(0xFF16A34A), Color(0xFFF0FDF4), '0 – 800',    '쾌적한 실내 수준'),
          _ThresholdLevel('보통',   Color(0xFFD97706), Color(0xFFFFFBEB), '800 – 1500', '창문 환기 권장'),
          _ThresholdLevel('나쁨',   Color(0xFFDC2626), Color(0xFFFFF1F2), '1500 – 2500','즉시 환기 필요'),
          _ThresholdLevel('매우나쁨', Color(0xFF9F1239), Color(0xFFFFE4E6), '2500 이상',  '모든 창문 개방'),
        ],
      ),
      _SensorThreshold(
        key: 'temp', code: 'TEMP', label: '온도', unit: '°C',
        color: AppColors.tempColor,
        levels: [
          _ThresholdLevel('쾌적', Color(0xFF16A34A), Color(0xFFF0FDF4), '18 – 28°C',        '최적 실내 온도'),
          _ThresholdLevel('주의', Color(0xFFD97706), Color(0xFFFFFBEB), '18↓ 또는 28↑',     '냉난방 조절 권장'),
          _ThresholdLevel('경고', Color(0xFFDC2626), Color(0xFFFFF1F2), '10↓ 또는 35↑',     '냉난방 가동 필요'),
          _ThresholdLevel('위험', Color(0xFF9F1239), Color(0xFFFFE4E6), '0↓ 또는 40↑',      '즉시 조치 필요'),
        ],
      ),
      _SensorThreshold(
        key: 'hum', code: 'HUM', label: '습도', unit: '%',
        color: AppColors.humidityColor,
        levels: [
          _ThresholdLevel('쾌적', Color(0xFF16A34A), Color(0xFFF0FDF4), '30 – 60%',          '쾌적한 실내 습도'),
          _ThresholdLevel('주의', Color(0xFFD97706), Color(0xFFFFFBEB), '30↓ 또는 60↑',      '가습·제습기 권장'),
          _ThresholdLevel('경고', Color(0xFFDC2626), Color(0xFFFFF1F2), '20↓ 또는 75↑',      '환기 또는 제습 필요'),
          _ThresholdLevel('위험', Color(0xFF9F1239), Color(0xFFFFE4E6), '10↓ 또는 90↑',      '즉시 조치 필요'),
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 페이지 헤더
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ALERT THRESHOLDS',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 2.2, color: AppColors.textLight,
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 6),
              Text(
                '경보 기준값',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppColors.textDark, letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '각 센서별 측정값에 따른 상태 분류 및 대응 지침입니다.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 센서 카드 목록
          ...sensors.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSensorCard(s),
          )),

          // 하단 안내
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ⓘ 기준값은 환경부 실내공기질 관리기준 및 WHO 가이드라인을 기반으로 설정되었습니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // 설정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('기준값 변경하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(_SensorThreshold s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 카드 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  s.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: s.color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(width: 4),
                Text(
                  s.unit,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // 4단 그리드
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: s.levels.asMap().entries.map((e) {
                final i = e.key;
                final lv = e.value;
                final isLast = i == s.levels.length - 1;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: lv.bg,
                      border: Border(
                        right: isLast
                            ? BorderSide.none
                            : const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 색상 도트 + 단계명
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: lv.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lv.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: lv.color,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 범위값
                        Text(
                          lv.range,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 설명
                        Text(
                          lv.desc,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 화면 상단 새 경보 토스트
// ─────────────────────────────────────────────
class _TopAlertToast extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onDismiss;
  const _TopAlertToast({required this.alert, required this.onDismiss});

  @override
  State<_TopAlertToast> createState() => _TopAlertToastState();
}

class _TopAlertToastState extends State<_TopAlertToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = widget.alert.severity == AlertSeverity.danger;
    final color = isDanger ? AppColors.danger : AppColors.warning;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDanger ? '위험 경보' : '주의 경보',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.alert.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.close, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Threshold 데이터 모델
// ─────────────────────────────────────────────
class _ThresholdLevel {
  final String label;
  final Color color;
  final Color bg;
  final String range;
  final String desc;
  const _ThresholdLevel(this.label, this.color, this.bg, this.range, this.desc);
}

class _SensorThreshold {
  final String key;
  final String code;
  final String label;
  final String unit;
  final Color color;
  final List<_ThresholdLevel> levels;
  const _SensorThreshold({
    required this.key,
    required this.code,
    required this.label,
    required this.unit,
    required this.color,
    required this.levels,
  });
}


