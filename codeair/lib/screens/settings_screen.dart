import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sensor_provider.dart';
import '../constants/app_colors.dart';
import '../services/alert_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _pm25Threshold = AlertService.pm25WarningThreshold;
  double _pm10Threshold = AlertService.pm10WarningThreshold;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pm25Threshold = prefs.getDouble('pm25Threshold') ?? AlertService.pm25WarningThreshold;
      _pm10Threshold = prefs.getDouble('pm10Threshold') ?? AlertService.pm10WarningThreshold;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.enable();
      if (!mounted) return;
      setState(() => _notificationsEnabled = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한이 거부되었습니다. 기기 설정에서 허용해주세요.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      await NotificationService.instance.disable();
      if (!mounted) return;
      setState(() => _notificationsEnabled = false);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pm25Threshold', _pm25Threshold);
    await prefs.setDouble('pm10Threshold', _pm10Threshold);

    if (!mounted) return;
    final provider = context.read<SensorProvider>();
    await provider.updateThresholds(_pm25Threshold, _pm10Threshold);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saveSettings,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        children: [
          // ── 섹션 헤더 ──
          const Text(
            'ALERT SETTINGS',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '경보 설정',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '푸시 알림 수신 여부 및 센서별 경보 임계값을 설정합니다.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // ── 푸시 알림 토글 카드 ──
          _card(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '푸시 알림',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '임계값 초과 시 기기로 알림 전송',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 임계값 슬라이더 카드 ──
          _card(
            children: [
              // PM2.5
              _buildSliderRow(
                label: 'PM2.5 경보 기준',
                code: 'PM2.5',
                unit: 'µg/m³',
                value: _pm25Threshold,
                min: 10,
                max: 100,
                color: AppColors.pm25Color,
                onChanged: (v) => setState(() => _pm25Threshold = v),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 20),
              // PM10
              _buildSliderRow(
                label: 'PM10 경보 기준',
                code: 'PM10',
                unit: 'µg/m³',
                value: _pm10Threshold,
                min: 20,
                max: 200,
                color: AppColors.pm10Color,
                onChanged: (v) => setState(() => _pm10Threshold = v),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── 하단 버전 표시 ──
          const Center(
            child: Column(
              children: [
                Text(
                  'CodeAir v1.0.0',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'IoT 공기질 모니터링 대시보드',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _buildSliderRow({
    required String label,
    required String code,
    required String unit,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).toInt(),
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.15),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.toStringAsFixed(0),
                style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontFamily: 'monospace')),
            Text('${max.toStringAsFixed(0)} $unit',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}
