import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';

/// Firestore `alerts` 컬렉션 읽기/읽음 처리 전용 서비스.
///
/// 경보 '생성'은 Cloudflare Worker가 단일 소스로 담당한다
/// (임계 초과 판정 + FCM 푸시 + Firestore 기록 + 5분 반복 쿨다운).
/// 따라서 앱은 경보를 만들지 않고 구독·표시·읽음 처리만 한다.
class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 설정 화면 슬라이더 기본값 (사용자가 임계값 미변경 시 표시용)
  static const double pm25WarningThreshold = 35.0;
  static const double pm10WarningThreshold = 80.0;

  Stream<List<AlertModel>> alertsStream({int limit = 50}) {
    return _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AlertModel.fromFirestore).toList());
  }

  Stream<int> unreadCountStream() {
    return _firestore
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({'isRead': true});
  }

  /// 여러 경보를 한 번에 읽음 처리 (그룹 카드용)
  Future<void> markManyAsRead(List<String> alertIds) async {
    final ids = alertIds.where((id) => !id.startsWith('local_')).toList();
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_firestore.collection('alerts').doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('alerts')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
