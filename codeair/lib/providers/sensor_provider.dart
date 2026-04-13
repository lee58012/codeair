import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/sensor_service.dart';
import '../services/alert_service.dart';

class SensorProvider extends ChangeNotifier {
  final SensorService _sensorService = SensorService();
  final AlertService _alertService = AlertService();

  SensorData? _latestData;
  List<SensorData> _history = [];
  bool _isLoading = false;
  String _error = '';
  String _deviceId = 'device_001';

  StreamSubscription? _latestSubscription;
  StreamSubscription? _historySubscription;

  SensorData? get latestData => _latestData;
  List<SensorData> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get deviceId => _deviceId;

  void initialize(String deviceId) {
    _deviceId = deviceId;
    _startListening();
  }

  void _startListening() {
    _isLoading = true;
    notifyListeners();

    _latestSubscription?.cancel();
    _historySubscription?.cancel();

    _latestSubscription = _sensorService
        .latestSensorStream(_deviceId)
        .listen((data) async {
      _latestData = data;
      _isLoading = false;
      _error = '';

      // 경보 체크
      if (data != null) {
        await _alertService.checkAndCreateAlerts(data);
      }

      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _historySubscription = _sensorService
        .historyStream(_deviceId)
        .listen((data) {
      _history = data;
      notifyListeners();
    });
  }

  void changeDevice(String deviceId) {
    _deviceId = deviceId;
    _latestData = null;
    _history = [];
    _startListening();
  }

  Future<void> sendDummyData() async {
    await _sensorService.pushDummyData(_deviceId);
  }

  @override
  void dispose() {
    _latestSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
