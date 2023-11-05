// weather_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/pages/weather_page_detail.dart';
import 'package:weather/service/weather_service.dart';

// 미드저니 API
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 백그라운드 이미지의 경로를 지정합니다.
const String _backgroundImagePath = 'assets/background/background-sunny01.png';

/// 날씨 정보를 표시하는 메인 페이지입니다.
class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _backgroundImagePath =
      'assets/background/background-sunny02.png'; // 기본 배경 이미지 경로

  final WeatherService _weatherService =
      WeatherService('5e20005e73bc298e26fbb7d0a73fa48d');
  Weather? _weather; // 현재 날씨 데이터를 저장하는 변수

  /// 사용자의 현재 위치를 기반으로 날씨 정보를 가져옵니다.
  Future<void> _fetchWeather() async {
    try {
      Position position = await _weatherService.getCurrentLocation();
      Weather weather = await _weatherService.getWeather(
          position.latitude, position.longitude);
      setState(() => _weather = weather);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('날씨 데이터를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

// 미드저니 API를 호출하여 이미지 URL을 가져오는 함수입니다.
  Future<void> _fetchImage(String weatherCondition) async {
    final response = await http.post(
      Uri.parse('https://prod.omnibridge.io/imagine'),
      headers: {
        'Authorization':
            'Bearer NWRiYTIyMDBkNjc0ZTA3ODIwNGExZGUzZGM4NTYxYzAyNzU0MmZiZDozMjNhM2E5OS1jNTI2LTQ0YjItYmJjZS01NTNmNjhiNzA4ZWY=',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'prompt': weatherCondition, // 날씨 조건을 텍스트 프롬프트로 전달
        'formats': 'PNG',
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final imageUrl = data['results'][0]['image_url']; // 생성된 이미지의 URL을 가져옵니다.
      setState(() {
        _backgroundImagePath = imageUrl; // 배경 이미지 경로를 업데이트합니다.
      });
    } else {
      // 에러 처리
      print('Failed to load image: ${response.statusCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 불러오는데 실패했습니다: ${response.statusCode}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather().then((_) {
      if (_weather != null) {
        _fetchImage(_weather!.mainCondition); // 날씨 정보를 기반으로 이미지를 가져옵니다.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          // 첫 번째 페이지: 메인 날씨 정보
          Center(
            child: Stack(
              children: [
                // 배경 이미지
                Positioned.fill(
                    child:
                        Image.asset(_backgroundImagePath, fit: BoxFit.cover)),
                // 온도와 날씨 상태 텍스트
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_weather?.temperature?.round() ?? ""}°',
                          style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text(_weather?.mainCondition ?? "",
                          style: TextStyle(fontSize: 18, color: Colors.black)),
                    ],
                  ),
                ),
                // 중앙 캐릭터 이미지
                Positioned(
                  left: screenWidth / 2 - 180,
                  top: screenHeight / 2 - 30,
                  child: Image.asset('assets/character/woman.png',
                      width: 500, height: 400, fit: BoxFit.contain),
                ),
                // 여기에 추가적인 날씨 관련 이미지나 위젯을 배치할 수 있습니다.
              ],
            ),
          ),
          // 두 번째 페이지: 상세 날씨 정보 페이지
          if (_weather != null)
            DetailWeatherPage(
                weather: _weather!), // 날씨 데이터가 있을 때만 DetailWeatherPage를 표시합니다.
        ],
      ),
    );
  }
}
