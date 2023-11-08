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

class _WeatherPageState extends State<WeatherPage> {
  // 기존 변수들...

  bool _isLoading = false; // 로딩 상태 변수 추가

  @override
  void initState() {
    super.initState();
    // 기존 initState 코드...
    _isLoading = false; // 초기 로딩 상태를 false로 설정
  }

  // 이미지 로딩 시작과 끝나는 지점에서 _isLoading 상태를 업데이트
  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _finishLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  // 기존 메서드들...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // 로딩 애니메이션을 위해 Stack 위젯 사용
        children: [
          PageView(
              // 기존 PageView 코드...
              ),
          if (_isLoading) // 로딩 중이면 애니메이션 표시
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
