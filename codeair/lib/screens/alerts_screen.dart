import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/alert_provider.dart';
import '../models/alert_model.dart';
import '../models/alert_group.dart';
import '../constants/app_colors.dart';

/// 오른쪽에서 슬라이드인하는 알림 드로어를 띄운다.
void showNotificationDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'notification-drawer',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const _NotificationDrawer(),
    transitionBuilder: (ctx, anim, _, child) {
      // 백드롭 페이드
      final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      // 드로어 슬라이드
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.32, 0, 0.24, 1),
      ));
      return Stack(
        children: [
          // 반투명 백드롭
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(fade),
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                color: const Color(0x2E0F172A),
              ),
            ),
          ),
          // 드로어 패널
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────
// 드로어 패널 본체
// ─────────────────────────────────────────────
class _NotificationDrawer extends StatelessWidget {
  const _NotificationDrawer();

  @override
  Widget build(BuildContext context) {
    final drawerWidth = (MediaQuery.of(context).size.width * 0.88).clamp(0.0, 360.0);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: drawerWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 32,
                offset: Offset(-8, 0),
              ),
            ],
          ),
          child: Consumer<AlertProvider>(
            builder: (context, provider, _) {
              final unread = provider.unreadCount;
              return Column(
                children: [
                  // ── 헤더
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 20,
                      right: 20,
                      bottom: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '알림',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                unread > 0 ? '미확인 $unread건' : '모두 확인됨',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 알림 리스트 (지속 경보는 그룹으로 묶어 표시)
                  Expanded(
                    child: provider.alerts.isEmpty
                        ? _buildEmptyState()
                        : Builder(
                            builder: (context) {
                              final groups = groupAlerts(provider.alerts);
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final group = groups[index];
                                  return _NotifCard(
                                    group: group,
                                    onTap: () => provider
                                        .markGroupAsRead(group.ids),
                                  );
                                },
                              );
                            },
                          ),
                  ),

                  // ── 하단 버튼
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: AppColors.border)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            unread > 0 ? provider.markAllAsRead : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unread > 0
                              ? AppColors.textDark
                              : Colors.white,
                          foregroundColor: unread > 0
                              ? Colors.white
                              : AppColors.textMuted,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side:
                                const BorderSide(color: AppColors.border),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                            unread > 0 ? '모두 읽음으로 표시' : '모두 확인됨'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '알림 없음',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '모든 센서가 정상 범위 내에서 작동 중입니다',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 알림 카드 (INFO · PUSH · 주의 · 경고 4종)
// ─────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AlertGroup group;
  final VoidCallback onTap;

  const _NotifCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final alert = group.latest;
    final isRead = !group.anyUnread;

    // ── severity별 스타일 ──
    final Color lvColor;
    final Color lvBg;
    final Color lvBdr;
    final String lvLabel;

    switch (alert.severity) {
      case AlertSeverity.info:
        lvColor = const Color(0xFF0284C7);
        lvBg    = isRead ? Colors.white : const Color(0xFFF0F9FF);
        lvBdr   = isRead ? AppColors.border : const Color(0xFFBAE6FD);
        lvLabel = 'INFO';
        break;
      case AlertSeverity.push:
        lvColor = const Color(0xFF16A34A);
        lvBg    = isRead ? Colors.white : const Color(0xFFF0FDF4);
        lvBdr   = isRead ? AppColors.border : const Color(0xFFBBF7D0);
        lvLabel = 'PUSH';
        break;
      case AlertSeverity.danger:
        lvColor = const Color(0xFFDC2626);
        lvBg    = isRead ? Colors.white : const Color(0xFFFFF1F2);
        lvBdr   = isRead ? AppColors.border : const Color(0xFFFECDD3);
        lvLabel = '경고';
        break;
      case AlertSeverity.warning:
        lvColor = const Color(0xFFD97706);
        lvBg    = isRead ? Colors.white : const Color(0xFFFFFBEB);
        lvBdr   = isRead ? AppColors.border : const Color(0xFFFCD34D);
        lvLabel = '주의';
        break;
    }

    // ── 제목 / 본문 구분 ──
    final bool isSystemLog =
        alert.severity == AlertSeverity.info ||
        alert.severity == AlertSeverity.push;
    final String title = isSystemLog
        ? alert.message
        : '${alert.typeLabel} 임계값 초과';
    final String? body = isSystemLog ? null : alert.message;

    // ── 시간 표시 (그룹은 '최초 발생' 시각 기준) ──
    final now = DateTime.now();
    final ts  = group.first;
    final String timeStr;
    if (ts.year == now.year && ts.month == now.month && ts.day == now.day) {
      timeStr = DateFormat('HH:mm').format(ts);
    } else if (now.difference(ts).inDays == 1) {
      timeStr = '어제';
    } else {
      timeStr = DateFormat('MM/dd').format(ts);
    }

    // ── 지속 정보 (같은 경보가 반복되어 묶인 경우) ──
    final bool persisting = group.persisting;
    final String persistText = group.persistLabel;

    return GestureDetector(
      onTap: isRead ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lvBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lvBdr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 레이블 행 ──
            Row(
              children: [
                if (!isRead)
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: lvColor, shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  lvLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: isRead ? AppColors.textLight : lvColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // ── 제목 ──
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSystemLog ? FontWeight.w500 : FontWeight.w700,
                color: isRead
                    ? AppColors.textMuted
                    : (isSystemLog ? AppColors.textMuted : AppColors.textDark),
                height: 1.4,
              ),
            ),
            // ── 지속 배지 (반복 묶임) ──
            if (persisting) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: lvColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew_rounded, size: 11, color: lvColor),
                    const SizedBox(width: 4),
                    Text(
                      persistText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: lvColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── 본문 (WARN/DANGER만) ──
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// 기존 route 방식과의 호환을 위해 유지
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // route로 접근 시 드로어를 전체화면처럼 감쌈
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: _NotificationDrawer(),
    );
  }
}
