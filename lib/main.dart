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

  // 상태바 스타일 (라이트 테마)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
          create: (_) {
            final provider = SensorProvider();
            provider.initialize('device_001');
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'CodeAir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.primary,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
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
