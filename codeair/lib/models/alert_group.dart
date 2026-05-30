import 'alert_model.dart';

/// 같은 종류가 지속 반복될 때 하나로 묶은 경보 그룹.
/// 알림 드로어와 SYSTEM LOG 터미널에서 공용으로 사용한다.
class AlertGroup {
  final AlertModel latest; // 대표(가장 최근) 경보 — 현재 값/심각도/메시지
  final bool groupable;    // 주의/위험 센서 경보만 그룹 대상
  DateTime first;          // 최초 발생 시각
  final DateTime last;     // 가장 최근 발생 시각 (= latest.timestamp)
  int count;               // 묶인 경보 수
  final List<String> ids;  // 멤버 문서 id (읽음 처리용)
  bool anyUnread;

  AlertGroup(this.latest, this.groupable)
      : first = latest.timestamp,
        last = latest.timestamp,
        count = 1,
        ids = [latest.id],
        anyUnread = !latest.isRead;

  /// 더 오래된 같은 상황의 경보를 묶는다 (목록은 최신→과거 순회).
  void addOlder(AlertModel a) {
    first = a.timestamp;
    count++;
    ids.add(a.id);
    if (!a.isRead) anyUnread = true;
  }

  /// 최초 발생부터 최근까지 지속된 시간(분)
  int get persistedMinutes => last.difference(first).inMinutes;

  /// 반복되어 묶인 상태인지 (지속 경보)
  bool get persisting => count > 1;

  /// "10분째 지속 · 3회" 형태의 지속 표시 문구 (단일 건이면 빈 문자열)
  String get persistLabel {
    if (!persisting) return '';
    if (persistedMinutes < 1) return '$count회 연속';
    return '${formatDuration(persistedMinutes)}째 지속 · $count회';
  }
}

/// 최신→과거로 정렬된 목록에서, 같은 종류의 지속 경보를 그룹으로 묶는다.
/// - 주의/위험 + 센서 항목(시스템 아님)만 그룹 대상
/// - 같은 종류의 직전 경보와 8분 이내 간격이면 동일 상황으로 간주
///   (Worker가 5분마다 기록하므로 안전하게 묶임)
/// - INFO/PUSH/시스템 로그는 개별 표시
/// - 종류별 '열린 그룹' 맵으로, 같은 시각에 CO₂·습도가 섞여 들어와도 종류별로 묶음
List<AlertGroup> groupAlerts(List<AlertModel> alerts) {
  const maxGap = Duration(minutes: 8);
  final groups = <AlertGroup>[];
  final open = <String, AlertGroup>{};

  for (final a in alerts) {
    final groupable = (a.severity == AlertSeverity.warning ||
            a.severity == AlertSeverity.danger) &&
        a.type != AlertType.system;

    if (!groupable) {
      groups.add(AlertGroup(a, false));
      continue;
    }

    final key = '${a.type}|${a.deviceId}';
    final g = open[key];
    if (g != null && g.first.difference(a.timestamp) <= maxGap) {
      g.addOlder(a);
    } else {
      final ng = AlertGroup(a, true);
      groups.add(ng);
      open[key] = ng;
    }
  }
  return groups;
}

/// 지속 시간(분)을 "N분" 또는 "N시간 M분"으로 포맷
String formatDuration(int minutes) {
  if (minutes < 1) return '1분 미만';
  if (minutes < 60) return '$minutes분';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h시간' : '$h시간 $m분';
}
