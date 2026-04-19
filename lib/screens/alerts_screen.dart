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
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '알람 로그 / 시스템 상태',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          Consumer<AlertProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox();
              return TextButton.icon(
                onPressed: provider.markAllAsRead,
                icon: const Icon(Icons.done_all,
                    size: 16, color: AppColors.primary),
                label: const Text(
                  '전체 읽음',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 요약
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: provider.alerts.isEmpty
                            ? const Color(0xFFDCFCE7)
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: provider.alerts.isEmpty
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: provider.alerts.isEmpty
                                  ? AppColors.success
                                  : AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.alerts.isEmpty
                                ? '모든 센서 정상'
                                : '경보 ${provider.alerts.length}건',
                            style: TextStyle(
                              color: provider.alerts.isEmpty
                                  ? const Color(0xFF166534)
                                  : AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '총 ${provider.alerts.length}건',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 다크 터미널 패널
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.logBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: provider.alerts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: provider.alerts.length,
                            itemBuilder: (context, index) {
                              final alert = provider.alerts[index];
                              return _TerminalEntry(
                                alert: alert,
                                onTap: () =>
                                    provider.markAsRead(alert.id),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
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
          SizedBox(height: 8),
          Text(
            '모든 센서 정상 작동 중...',
            style: TextStyle(
              color: AppColors.logText,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No alerts detected.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalEntry extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  const _TerminalEntry({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(alert.timestamp);
    final isCritical = alert.severity == AlertSeverity.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임스탬프
            Text(
              '[$timeStr]',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            // 메시지
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  color: isCritical
                      ? const Color(0xFFF87171) // red-400
                      : const Color(0xFFFBBF24), // amber-400
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            // 읽음 여부
            if (!alert.isRead)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 3, left: 6),
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFF87171)
                      : const Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
