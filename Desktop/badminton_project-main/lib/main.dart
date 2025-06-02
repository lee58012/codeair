import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'data/constant.dart';

import 'firebase_options.dart';
import 'intro/intro_page.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  showFlutterNotification(message);

  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'baddy_channel', // id
    'Baddy 알림', // title
    description: 'Baddy 어플에서 사용하는 알림입니다', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  //알림 보낼 때 어떤 식으로 보낼지 정의(알림 창, 배지, 소리)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

//알림을 직접 보이는 함수
//서버에 전달하는 데이터를 message 클래스에 담아서 각각 보여줌
void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'noti_launch',
        ),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await setupFlutterNotifications();
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }
  AuthRepository.initialize(appKey: 'faa6f8639d7339089700ff192901b57f');
  runApp(const MyApp());
}

//String? _token;
String? initialMessage;
bool _resolved = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      FirebaseMessaging.instance.getInitialMessage().then((value) {
        _resolved = true;
        initialMessage = value?.data.toString();
      });
      // 앱이 실행될 때 메세지를 받으면 처리하는 콜백 함수
      FirebaseMessaging.onMessage.listen(showFlutterNotification);

      // 앱이 백그라운드에서 실행 중일 때 사용자가 알람을 탭하여 앱을 열 때 호출
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        //String linkId =  message.data['link'];
        //Get.to(LinkPage(link: linkId));
        print('A new onMessageOpenedApp event was published! ${message.data}');
      });
    }
    return GetMaterialApp(
      title: Constant.APP_NAME,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white70),
        useMaterial3: true,
      ),
      home: IntroPage(),
    );
  }
}
