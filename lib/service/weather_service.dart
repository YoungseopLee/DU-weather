// weather_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class WeatherService {
  // OpenWeatherMap One Call API의 기본 URL입니다.
  static const BASE_URL = 'https://api.openweathermap.org/data/3.0/onecall';
  final String apiKey;

  WeatherService(this.apiKey);

  // 현재 위치의 위도와 경도를 가져오는 메서드
  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 정보를 사용할 수 있는 권한이 없습니다.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 정보를 사용할 수 있는 권한이 없습니다.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // 위치 정보에 기반하여 날씨 데이터를 가져오는 함수
  Future<Weather> getWeather(double latitude, double longitude) async {
    print('위도: $latitude, 경도: $longitude'); // 현재 위치 로그 확인
    final url =
        '$BASE_URL?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    print('API 응답: ${response.body}'); // API 응답 로그 확인

    if (response.statusCode == 200) {
      var weatherJson = json
          .decode(response.body); // 이제 hourly 데이터도 함께 파싱하여 Weather 객체를 만듭니다.
      return Weather.fromJson(weatherJson);
    } else {
      throw Exception('날씨 데이터를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  Future<void> getWeatherAndNotify() async {
    try {
      final currentPosition = await getCurrentLocation();
      final weatherData =
          await getWeather(currentPosition.latitude, currentPosition.longitude);
      // 날씨 데이터를 기반으로 알림을 보냅니다.
      for (var hourlyWeather in weatherData.hourly) {
        if (hourlyWeather.dateTime
            .isBefore(DateTime.now().add(Duration(hours: 24)))) {
          if (hourlyWeather.condition.toLowerCase().contains('rain')) {
            // 비 예보가 있으면 알림을 보냅니다.
            final notificationTime =
                DateFormat('ha').format(hourlyWeather.dateTime);
            await NotificationService().showNotification(
                0, // ID는 고유해야 합니다. 반복적인 알림을 위해 다른 값을 사용해야 합니다.
                '비 소식', // 알림 제목
                '$notificationTime 쯤 비소식이 있어요!' // 알림 내용
                );
            break; // 첫 번째 비 예보에 대한 알림만 보냅니다.
          }
        }
      }
    } catch (e) {
      print('에러 발생: $e');
    }
  }
}

// 날씨 정보를 가져오고 콜백을 통해 UI를 업데이트하는 함수입니다.
void getWeatherData(Function(Weather) onWeatherUpdated) async {
  WeatherService weatherService =
      WeatherService('5e20005e73bc298e26fbb7d0a73fa48d'); // 실제 API 키를 여기에 넣으세요.
  try {
    final currentPosition = await weatherService.getCurrentLocation();
    final weatherData = await weatherService.getWeather(
        currentPosition.latitude, currentPosition.longitude);

    // 날씨 데이터를 가져왔으므로, 이를 처리하는 콜백 함수를 호출합니다.
    onWeatherUpdated(weatherData);
  } catch (e) {
    // 에러 처리
    print('에러 발생: $e');
  }
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> initNotification() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // 앱 아이콘 설정

    // 아래 코드가 수정되었습니다.
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    // 아래 코드가 수정되었습니다.
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS, // 여기서 iOS 대신 Darwin을 사용합니다.
            macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'weather_channel_id', // 채널 ID
            'Weather Channel', // 채널 이름
            channelDescription: 'Channel for Weather notification', // 채널 설명
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
