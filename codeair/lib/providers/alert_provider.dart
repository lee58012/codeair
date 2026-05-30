import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();

  List<AlertModel> _firestoreAlerts = [];
  final List<AlertModel> _localLogs = [];
  int _unreadCount = 0;

  StreamSubscription? _alertsSub;
  StreamSubscription? _unreadSub;
  StreamSubscription? _connectedSub;

  // 마지막으로 기록된 연결 상태 (중복 로그 방지)
  bool? _lastConnected;

  /// Firestore 경보 + 로컬 시스템 이벤트를 시간순 병합
  List<AlertModel> get alerts {
    final merged = [..._localLogs, ..._firestoreAlerts];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  /// Firestore 미읽음만 카운트 (시스템 로그는 자동 읽음)
  int get unreadCount => _unreadCount;

  void initialize() {
    _alertsSub = _alertService.alertsStream().listen((data) {
      _firestoreAlerts = data;
      notifyListeners();
    });
    _unreadSub = _alertService.unreadCountStream().listen((count) {
      _unreadCount = count;
      notifyListeners();
    });

    // 앱 시작 로그 (1회만)
    _addLocal(AlertSeverity.info, '앱 시작 · 센서 스트림 초기화');

    // Firebase 연결 상태: 상태가 바뀔 때만 로그 추가
    _connectedSub = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) {
      final connected = event.snapshot.value == true;

      // 이전 상태와 동일하면 로그 추가 안 함
      if (_lastConnected == connected) return;
      _lastConnected = connected;

      _addLocal(
        connected ? AlertSeverity.info : AlertSeverity.warning,
        connected
            ? 'Firebase 연결됨 · 실시간 데이터 스트림 활성'
            : 'Firebase 연결 끊김 · 재연결 시도 중',
      );
    });
  }

  void _addLocal(AlertSeverity severity, String message) {
    _localLogs.insert(0, AlertModel.local(severity: severity, message: message));
    if (_localLogs.length > 50) _localLogs.removeLast();
    notifyListeners();
  }

  /// 외부에서 시스템 로그 추가 (알림 전송 확인 등)
  void addSystemLog(AlertSeverity severity, String message) =>
      _addLocal(severity, message);

  Future<void> markAsRead(String alertId) async {
    await _alertService.markAsRead(alertId);
  }

  /// 그룹 카드에 속한 모든 경보를 읽음 처리
  Future<void> markGroupAsRead(List<String> alertIds) async {
    await _alertService.markManyAsRead(alertIds);
  }

  Future<void> markAllAsRead() async {
    await _alertService.markAllAsRead();
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    _unreadSub?.cancel();
    _connectedSub?.cancel();
    super.dispose();
  }
}
