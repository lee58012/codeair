import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM 백그라운드 메시지 핸들러 (top-level 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드/종료 상태에서는 시스템이 자동으로 알림을 표시하므로
  // 별도 처리가 필요 없지만, 데이터 메시지 처리가 필요하면 여기에 작성.
  debugPrint('[FCM] 백그라운드 메시지 수신: ${message.messageId}');
}

/// FCM 푸시 알림 서비스
/// - 권한 요청
/// - 토큰 발급 → Firebase RTDB에 저장 (Cloudflare Worker가 읽음)
/// - 포그라운드 메시지 → 로컬 알림 표시
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static const String _channelId = 'codeair_alerts';
  static const String _channelName = 'CodeAir 경보';
  static const String _channelDesc = '공기질 경보 알림';
  static const String _prefKey = 'notificationsEnabled';

  /// 웹 푸시용 VAPID 공개키 (Firebase Console → Cloud Messaging → 웹 푸시 인증서)
  static const String _vapidKey =
      'BJtr_eQxWrAaPz6imweJqpjdhleKeNLxUAx4y6Sqb7zofIzA3H_7iO2vOWY6nOQ-aFdvpCm4Jl3RIBV9D7EaoLI';

  bool _initialized = false;

  /// 앱 시작 시 호출. 알림이 켜져 있으면 토큰 등록까지 진행.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 웹은 별도 VAPID 설정이 필요하므로 모바일에서만 로컬 알림 채널 구성
    if (!kIsWeb) {
      await _setupLocalNotifications();
    }

    // 포그라운드 메시지 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 토큰 갱신 시 Firebase에 재저장
    _fcm.onTokenRefresh.listen((token) async {
      final enabled = await isEnabled();
      if (enabled) await _saveToken(token);
    });

    // 저장된 설정이 켜져 있으면 토큰 등록
    if (await isEnabled()) {
      await enable();
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _local.initialize(initSettings);

    // Android 알림 채널 생성
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || kIsWeb) return;

    _local.show(
      notification.hashCode,
      notification.title ?? 'CodeAir 경보',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// 알림 켜기 — 권한 요청 + 토큰 저장
  Future<bool> enable() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      await _setEnabledPref(false);
      return false;
    }

    final token = kIsWeb
        ? await _fcm.getToken(vapidKey: _vapidKey)
        : await _fcm.getToken();
    if (token != null) {
      await _saveToken(token);
    }
    await _setEnabledPref(true);
    return true;
  }

  /// 알림 끄기 — 토큰 삭제
  Future<void> disable() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.child('fcm_tokens/${_sanitize(token)}').remove();
      }
    } catch (e) {
      debugPrint('[FCM] 토큰 삭제 실패: $e');
    }
    await _setEnabledPref(false);
  }

  /// 토큰을 RTDB `fcm_tokens/{token}` 에 저장
  Future<void> _saveToken(String token) async {
    await _db.child('fcm_tokens/${_sanitize(token)}').set({
      'token': token,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'platform': defaultTargetPlatform.name,
    });
  }

  /// RTDB 키로 쓸 수 없는 문자 치환
  String _sanitize(String token) =>
      token.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> _setEnabledPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
