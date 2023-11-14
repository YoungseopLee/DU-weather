// main.dart
import 'package:flutter/material.dart';
import 'package:weather/pages/weather_page.dart';

import 'service/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 필요한 Flutter 바인딩을 초기화합니다.
  await NotificationService().initNotification(); // 알림 서비스를 초기화합니다.
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: WeatherPage());
  }
}
