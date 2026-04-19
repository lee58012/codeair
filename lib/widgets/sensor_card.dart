import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 디자인 참고: code-air MetricCard (이미지 스타일)
/// 아이콘+타이틀+뱃지(상단), 큰 숫자(하단), 상태별 배경 틴트
class SensorCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color accentColor;
  final IconData icon;
  final bool isExceeded;
  final String? statusLabel;
  final Color? statusColor;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.icon,
    this.isExceeded = false,
    this.statusLabel,
    this.statusColor,
  });

  Color get _dotColor => statusColor ?? (isExceeded ? AppColors.danger : AppColors.success);
  String get _label => statusLabel ?? (isExceeded ? '위험' : '좋음');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dotColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _dotColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 상단: 아이콘 + 타이틀 + 뱃지
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _dotColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    color: _dotColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 하단: 큰 숫자 + 단위
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SensorCardSkeleton extends StatelessWidget {
  const SensorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(18, 18),
              const SizedBox(width: 8),
              _shimmer(80, 12),
              const Spacer(),
              _shimmer(40, 20),
            ],
          ),
          const SizedBox(height: 12),
          _shimmer(110, 36),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
