import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/sensor_scale.dart';
import 'aqi_bar.dart';

/// 우측 사이드 — Hero 외 다른 센서들 컴팩트 리스트
class SecondaryRail extends StatelessWidget {
  final String heroKey;
  final Map<String, double?> values;
  final void Function(String key) onSelect;
  final int totalAlertsToday;
  final int alertCount;

  const SecondaryRail({
    super.key,
    required this.heroKey,
    required this.values,
    required this.onSelect,
    this.totalAlertsToday = 0,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final others = SensorScales.all.where((s) => s.key != heroKey).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Text(
              'OTHER METRICS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.textLight,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // 센서 리스트
          ...others.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final v = values[s.key];
            final tier = s.tierOf(v);
            final chipFg = SensorScales.colorForTier(tier);
            final isLast = i == others.length - 1;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(s.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      s.code,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.6,
                                        fontFamily: 'monospace',
                                        color: s.color,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      v?.toStringAsFixed(1) ?? '--',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.2,
                                        color: AppColors.textDark,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.unit,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.tierLabel(tier),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipFg,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AqiBar(scale: s, value: v, compact: true),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 오늘 경보 요약
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY · 경보 요약',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.textLight,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _miniStat('총 경보', '$alertCount', AppColors.tierBad)),
                    const SizedBox(width: 10),
                    Expanded(child: _miniStat('초과 횟수', '$totalAlertsToday회',
                        totalAlertsToday > 0 ? AppColors.tierBad : AppColors.tierGood)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: accent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
