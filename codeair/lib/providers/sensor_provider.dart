import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // SharedPreferences에서 로드된 임계값
  double pm25Threshold = AlertService.pm25WarningThreshold;
  double pm10Threshold = AlertService.pm10WarningThreshold;

  StreamSubscription? _latestSubscription;
  StreamSubscription? _historySubscription;

  SensorData? get latestData => _latestData;
  List<SensorData> get history => _history;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get deviceId => _deviceId;

  Future<void> initialize(String deviceId) async {
    _deviceId = deviceId;
    await _loadThresholds();
    _startListening();
  }

  /// SharedPreferences에서 저장된 임계값 로드
  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    pm25Threshold = prefs.getDouble('pm25Threshold') ?? AlertService.pm25WarningThreshold;
    pm10Threshold = prefs.getDouble('pm10Threshold') ?? AlertService.pm10WarningThreshold;
  }

  /// 설정 화면에서 저장 시 호출 — 즉시 반영
  Future<void> updateThresholds(double pm25, double pm10) async {
    pm25Threshold = pm25;
    pm10Threshold = pm10;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pm25Threshold', pm25);
    await prefs.setDouble('pm10Threshold', pm10);
    notifyListeners();
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

      // 경보 체크 — 현재 임계값 전달
      if (data != null) {
        await _alertService.checkAndCreateAlerts(
          data,
          pm25Threshold: pm25Threshold,
          pm10Threshold: pm10Threshold,
        );
      }

      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _historySubscription = _sensorService.historyStream(_deviceId).listen((data) {
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
