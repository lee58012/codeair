import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/sensor_scale.dart';

/// AQI 스케일 바 — 그라디언트 + 틱마크 + 현재값 썸 + 라벨
class AqiBar extends StatelessWidget {
  final SensorScale scale;
  final double? value;
  final bool compact; // true → mini (rail용)

  const AqiBar({
    super.key,
    required this.scale,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SensorScales.gradientFor(scale.key);
    final stops = SensorScales.gradientStopsFor(scale.key);
    final maxVal = scale.scaleMax;
    final v = value ?? 0;
    final pct = (v / maxVal).clamp(0.0, 1.0);

    final barHeight = compact ? 6.0 : 8.0;
    final thumbSize = compact ? 12.0 : 16.0;

    final bar = LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        return SizedBox(
          height: thumbSize, // 썸이 바깥으로 약간 튀어나오게
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 그라디언트 바
              Positioned(
                top: (thumbSize - barHeight) / 2,
                left: 0, right: 0,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    gradient: LinearGradient(
                      colors: colors,
                      stops: stops,
                    ),
                  ),
                ),
              ),
              // 틱 마크
              ...scale.ticks.map((t) {
                final tpx = (t.at / maxVal).clamp(0.0, 1.0) * width;
                return Positioned(
                  left: tpx - 0.5,
                  top: (thumbSize - barHeight) / 2 - 2,
                  child: Container(
                    width: 1,
                    height: barHeight + 4,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                );
              }),
              // 썸
              Positioned(
                left: (pct * width) - (thumbSize / 2),
                top: 0,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.10),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x38000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (compact) return bar;

    // Full bar: 바 + 라벨 영역
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: bar,
        ),
        SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: scale.ticks.map((t) {
                  final tpx = (t.at / maxVal).clamp(0.0, 1.0);
                  final align = tpx < 0.06
                      ? CrossAxisAlignment.start
                      : tpx > 0.94
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.center;
                  final pxLeft = tpx * width;
                  final translate = tpx < 0.06
                      ? 0.0
                      : tpx > 0.94
                          ? -1.0
                          : -0.5;
                  return Positioned(
                    left: pxLeft,
                    top: 0,
                    child: FractionalTranslation(
                      translation: Offset(translate, 0),
                      child: Column(
                        crossAxisAlignment: align,
                        children: [
                          Text(
                            t.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            t.at.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textLight,
                              fontFamily: 'monospace',
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
