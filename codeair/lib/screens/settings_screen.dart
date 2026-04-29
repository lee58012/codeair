import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sensor_provider.dart';
import '../constants/app_colors.dart';
import '../services/alert_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceIdController = TextEditingController();
  double _pm25Threshold = AlertService.pm25WarningThreshold;
  double _pm10Threshold = AlertService.pm10WarningThreshold;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _deviceIdController.text = prefs.getString('deviceId') ?? 'device_001';
      _pm25Threshold = prefs.getDouble('pm25Threshold') ?? AlertService.pm25WarningThreshold;
      _pm10Threshold = prefs.getDouble('pm10Threshold') ?? AlertService.pm10WarningThreshold;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceId', _deviceIdController.text);
    await prefs.setDouble('pm25Threshold', _pm25Threshold);
    await prefs.setDouble('pm10Threshold', _pm10Threshold);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);

    if (!mounted) return;
    final provider = context.read<SensorProvider>();
    provider.changeDevice(_deviceIdController.text);
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
        title: const Text(
          '설정',
          style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '저장',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 기기 설정 ──
          const _SectionHeader(title: '기기 설정'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              TextField(
                controller: _deviceIdController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  labelText: '기기 ID',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  hintText: 'device_001',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.device_hub, color: AppColors.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 경보 설정 ──
          const _SectionHeader(title: '경보 설정'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Text('푸시 알림', style: TextStyle(color: AppColors.textDark, fontSize: 17)),
                    ],
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              _ThresholdSlider(
                label: 'PM2.5 경보 기준',
                value: _pm25Threshold,
                min: 10,
                max: 100,
                unit: 'µg/m³',
                color: AppColors.pm25Color,
                onChanged: (v) => setState(() => _pm25Threshold = v),
              ),
              const SizedBox(height: 16),
              _ThresholdSlider(
                label: 'PM10 경보 기준',
                value: _pm10Threshold,
                min: 20,
                max: 200,
                unit: 'µg/m³',
                color: AppColors.pm10Color,
                onChanged: (v) => setState(() => _pm10Threshold = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 공기질 기준 안내 ──
          const _SectionHeader(title: '공기질 기준 (국내 기준)'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _StandardRow(
                label: 'PM2.5',
                good: '0~15',
                moderate: '16~35',
                bad: '36~75',
                veryBad: '76+',
                unit: 'µg/m³',
              ),
              const Divider(color: AppColors.border, height: 20),
              _StandardRow(
                label: 'PM10',
                good: '0~30',
                moderate: '31~80',
                bad: '81~150',
                veryBad: '151+',
                unit: 'µg/m³',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 개발자 옵션 ──
          const _SectionHeader(title: '개발자 옵션'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              Consumer<SensorProvider>(
                builder: (context, provider, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await provider.sendDummyData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('테스트 데이터 전송됨'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.science_outlined, color: AppColors.primary),
                      label: const Text(
                        '테스트 데이터 전송',
                        style: TextStyle(color: AppColors.primary, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          Center(
            child: Column(
              children: const [
                Text('CodeAir v1.0.0',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                SizedBox(height: 4),
                Text('IoT 공기질 모니터링 대시보드',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }
}

// ── 섹션 헤더 ──
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── 설정 카드 ──
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// ── 임계값 슬라이더 ──
class _ThresholdSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(0)} $unit',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 5).toInt(),
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── 공기질 기준 행 ──
class _StandardRow extends StatelessWidget {
  final String label;
  final String good;
  final String moderate;
  final String bad;
  final String veryBad;
  final String unit;

  const _StandardRow({
    required this.label,
    required this.good,
    required this.moderate,
    required this.bad,
    required this.veryBad,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            _chip('좋음 $good', AppColors.success),
            const SizedBox(width: 6),
            _chip('보통 $moderate', AppColors.warning),
            const SizedBox(width: 6),
            _chip('나쁨 $bad', AppColors.danger),
            const SizedBox(width: 6),
            _chip('매우나쁨 $veryBad $unit', AppColors.danger),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
