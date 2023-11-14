import 'package:flutter/material.dart';
import 'package:weather/pages/weather_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initNotification();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeatherPage(),
    );
  }
}
