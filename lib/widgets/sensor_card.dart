import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 디자인 참고: code-air MetricCard
/// 흰색 카드, 큰 숫자, 상태 dot + 텍스트
class SensorCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color accentColor;
  final IconData icon;
  final bool isExceeded;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.icon,
    this.isExceeded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.border,
          width: isExceeded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // 수치 (크게)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 상태 dot
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isExceeded ? AppColors.danger : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isExceeded ? '위험 (기준 초과)' : '좋음',
                style: TextStyle(
                  color: isExceeded ? AppColors.danger : AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
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
          _shimmer(70, 12),
          const SizedBox(height: 10),
          _shimmer(110, 38),
          const SizedBox(height: 14),
          _shimmer(90, 14),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
