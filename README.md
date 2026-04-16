# 🌬️ CodeAir

IoT 기기로 수집된 **미세먼지(PM10), 초미세먼지(PM2.5), 온도, 습도** 데이터를 실시간으로 모니터링하는 Flutter 대시보드 앱입니다.

## 주요 기능

- 📊 실시간 센서 데이터 대시보드 (PM2.5, PM10, 온도, 습도)
- 📈 각 센서별 시간대 추이 차트
- 🚨 임계값 초과 시 자동 경보 생성 및 알림
- ⚙️ 기기 ID / 경보 기준값 설정
- 📱 Android + Web 동시 지원

## 기술 스택

| 분류 | 기술 |
|------|------|
| Frontend | Flutter (Dart) |
| 실시간 데이터 | Firebase Realtime Database |
| 경보 이력 | Firebase Firestore |
| 상태 관리 | Provider |
| 차트 | fl_chart |

## 프로젝트 구조

```
lib/
├── main.dart
├── models/          # 데이터 모델 (SensorData, AlertModel)
├── services/        # Firebase 연동 (SensorService, AlertService)
├── providers/       # 상태 관리 (SensorProvider, AlertProvider)
├── screens/         # 화면 (Dashboard, Alerts, Settings)
├── widgets/         # 재사용 위젯 (SensorCard, MiniChart)
└── constants/       # 색상 상수 (AppColors)
```

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 웹 실행
flutter run -d chrome

# 안드로이드 실행
flutter run -d android
```

> Firebase 연동을 위해 `google-services.json` 및 `firebase_options.dart` 설정이 필요합니다.
