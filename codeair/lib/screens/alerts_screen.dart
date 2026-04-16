import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import '../constants/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '경보 알림',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Consumer<AlertProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox();
              return TextButton.icon(
                onPressed: provider.markAllAsRead,
                icon: const Icon(Icons.done_all, size: 16, color: AppColors.primary),
                label: const Text(
                  '전체 읽음',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, provider, _) {
          if (provider.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: AppColors.textSecondary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '경보가 없습니다',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '센서 수치가 정상 범위 내에 있습니다',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.alerts.length,
            itemBuilder: (context, index) {
              final alert = provider.alerts[index];
              return _AlertCard(
                alert: alert,
                onTap: () => provider.markAsRead(alert.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  Color get _severityColor =>
      alert.severity == AlertSeverity.danger ? AppColors.danger : AppColors.warning;

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.pm25:
        return Icons.blur_on;
      case AlertType.pm10:
        return Icons.grain;
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.humidity:
        return Icons.water_drop_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.isRead
              ? AppColors.cardBackground
              : _severityColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? Colors.white10
                : _severityColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon, color: _severityColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alert.severity == AlertSeverity.danger ? '위험' : '경고',
                          style: TextStyle(
                            color: _severityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.typeLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm').format(alert.timestamp),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
