import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../models/alert_group.dart';

class TerminalLog extends StatelessWidget {
  final List<AlertModel> alerts;

  const TerminalLog({super.key, required this.alerts});

  static const _logBg     = Color(0xFF0F172A);
  static const _logFg     = Color(0xFFCBD5E1);
  static const _logBorder = Color(0xFF1E293B);
  static const _logMuted  = Color(0xFF475569);

  Color _levelColor(AlertSeverity sev) {
    switch (sev) {
      case AlertSeverity.danger:  return const Color(0xFFF87171); // 빨강
      case AlertSeverity.warning: return const Color(0xFFFBBF24); // 노랑
      case AlertSeverity.info:    return const Color(0xFF38BDF8); // 파랑
      case AlertSeverity.push:    return const Color(0xFF4ADE80); // 초록
    }
  }

  String _levelLabel(AlertSeverity sev) {
    switch (sev) {
      case AlertSeverity.danger:  return 'ERR ';
      case AlertSeverity.warning: return 'WARN';
      case AlertSeverity.info:    return 'INFO';
      case AlertSeverity.push:    return 'PUSH';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _logBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _logBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChrome(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 360),
            child: alerts.isEmpty ? _buildEmpty() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChrome() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: const BoxDecoration(
      color: _logBg,
      border: Border(bottom: BorderSide(color: _logBorder)),
    ),
    child: Row(
      children: [
        _Dot(), const SizedBox(width: 6),
        _Dot(), const SizedBox(width: 6),
        _Dot(),
        const SizedBox(width: 10),
        const Text(
          'SYSTEM LOG · codeair/alert-stream',
          style: TextStyle(fontFamily: 'monospace', fontSize: 10,
              letterSpacing: 1.5, color: _logMuted),
        ),
        const Spacer(),
        const Text('● LIVE',
          style: TextStyle(fontFamily: 'monospace', fontSize: 10,
              color: Color(0xFF4ADE80), letterSpacing: 0.8)),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('[SYSTEM INFO]',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11,
                letterSpacing: 2, color: _logMuted)),
        SizedBox(height: 6),
        Text('모든 센서 정상 작동 중...',
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: _logFg)),
      ]),
    ),
  );

  Widget _buildList() {
    // 드로어와 동일하게 지속 경보를 묶어 한 줄로 표시
    final groups = groupAlerts(alerts);
    return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    itemCount: groups.length,
    itemBuilder: (context, idx) {
      final g = groups[idx];
      final a = g.latest;
      final color = _levelColor(a.severity);
      // 시각은 최초 발생 기준, 지속 시 접미사 표시
      final timeStr = DateFormat('HH:mm:ss').format(g.first);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text(timeStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: _logMuted)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              child: Text('[${_levelLabel(a.severity)}]',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11,
                    color: color, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: a.message),
                  if (g.persisting)
                    TextSpan(
                      text: '  (${g.persistLabel})',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                ]),
                style: TextStyle(fontFamily: 'monospace', fontSize: 11,
                    color: a.severity == AlertSeverity.danger ? const Color(0xFFF87171) : _logFg),
              ),
            ),
          ],
        ),
      );
    },
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: const BoxDecoration(color: Color(0xFF374151), shape: BoxShape.circle),
  );
}

