import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/sensor_service.dart';
import '../services/alert_service.dart';

class SensorProvider extends ChangeNotifier {
  final SensorService _sensorService = SensorService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

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
  /// 로컬(SharedPreferences) + Firebase(config/thresholds) 양쪽에 저장.
  /// Firebase 저장본은 Cloudflare Worker가 읽어 FCM 경보 판단에 사용.
  Future<void> updateThresholds(double pm25, double pm10) async {
    pm25Threshold = pm25;
    pm10Threshold = pm10;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pm25Threshold', pm25);
    await prefs.setDouble('pm10Threshold', pm10);

    // Cloudflare Worker가 읽을 수 있도록 Firebase에도 저장
    try {
      await _db.child('config/thresholds').set({
        'pm25': pm25,
        'pm10': pm10,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[Threshold] Firebase 저장 실패: $e');
    }

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

      // 경보 생성은 Cloudflare Worker가 단일 소스로 처리한다.
      // (임계 초과 시 Worker가 FCM 푸시 + Firestore 경보 기록을 함께 수행하며,
      //  첫 초과 후 5분 반복 / 정상 복귀 시 리셋 쿨다운을 적용)
      // 앱은 Firestore 경보 스트림을 구독해 표시만 한다.

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

  /// 당겨서 새로고침 — 실시간 스트림을 재구독해 최신 상태로 재동기화
  Future<void> refresh() async {
    _startListening();
  }

  @override
  void dispose() {
    _latestSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }
}
