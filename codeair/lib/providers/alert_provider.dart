import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();

  List<AlertModel> _alerts = [];
  int _unreadCount = 0;
  StreamSubscription? _alertsSubscription;
  StreamSubscription? _unreadSubscription;

  List<AlertModel> get alerts => _alerts;
  int get unreadCount => _unreadCount;

  void initialize() {
    _alertsSubscription = _alertService.alertsStream().listen((data) {
      _alerts = data;
      notifyListeners();
    });
    _unreadSubscription = _alertService.unreadCountStream().listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String alertId) async {
    await _alertService.markAsRead(alertId);
  }

  Future<void> markAllAsRead() async {
    await _alertService.markAllAsRead();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
