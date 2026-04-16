import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/sensor_provider.dart';
import 'providers/alert_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CodeAirApp());
}

class CodeAirApp extends StatelessWidget {
  const CodeAirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SensorProvider()..initialize('device_001'),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'CodeAir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Pretendard',
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const DashboardScreen(),
          '/alerts': (_) => const AlertsScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
