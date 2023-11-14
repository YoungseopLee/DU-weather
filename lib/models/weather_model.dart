// weather_model.dart

import 'dart:math';

class Weather {
  final List<DailyWeather> daily;
  final String cityName;
  final double temperature;
  final String mainCondition;
  final int humidity;
  final double windSpeed;
  final List<HourlyWeather> hourly; // 시간별 날씨 데이터 리스트

  final DateTime sunrise;
  final DateTime sunset;

  Weather(
      {required this.cityName,
      required this.temperature,
      required this.mainCondition,
      required this.humidity,
      required this.windSpeed,
      required this.hourly,
      required this.daily,
      required this.sunrise,
      required this.sunset});

  double get maxTemperature =>
      daily.isNotEmpty ? daily.map((d) => d.maxTemperature).reduce(max) : 0.0;

  double get minTemperature =>
      daily.isNotEmpty ? daily.map((d) => d.minTemperature).reduce(min) : 0.0;

  factory Weather.fromJson(Map<String, dynamic> json) {
    var hourlyJson = json['hourly'] as List;
    List<HourlyWeather> hourlyWeather =
        hourlyJson.map((i) => HourlyWeather.fromJson(i)).toList();

    var dailyJson = json['daily'] as List;
    List<DailyWeather> dailyWeather =
        dailyJson.map((i) => DailyWeather.fromJson(i)).toList();
    // 일출 및 일몰 시간을 UNIX 타임스탬프에서 DateTime 객체로 변환
    DateTime sunrise = DateTime.fromMillisecondsSinceEpoch(
        json['current']['sunrise'] * 1000,
        isUtc: true);
    DateTime sunset = DateTime.fromMillisecondsSinceEpoch(
        json['current']['sunset'] * 1000,
        isUtc: true);

    return Weather(
        cityName: json['timezone'],
        temperature: json['current']['temp'].toDouble(),
        mainCondition: json['current']['weather'][0]['description'],
        humidity: json['current']['humidity'].toInt(),
        windSpeed: json['current']['wind_speed'].toDouble(),
        hourly: hourlyWeather,
        daily: dailyWeather,
        sunrise: sunrise,
        sunset: sunset);
  }
}

class DailyWeather {
  final DateTime dateTime;
  final double maxTemperature;
  final double minTemperature;
  final String condition;
  final int precipitationChance;

  DailyWeather({
    required this.dateTime,
    required this.maxTemperature,
    required this.minTemperature,
    required this.condition,
    required this.precipitationChance,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    int pop = (json['pop'] * 100).toInt(); // JSON에서 강수확률 필드를 추가합니다.
    return DailyWeather(
      dateTime:
          DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000, isUtc: true),
      maxTemperature: json['temp']['max'].toDouble(),
      minTemperature: json['temp']['min'].toDouble(),
      condition: json['weather'][0]['description'],
      precipitationChance: pop, // 강수 확률 필드 추가
    );
  }
}

class HourlyWeather {
  final DateTime dateTime;
  final double temperature;
  final String condition;
  final int? humidity; // Nullable로 변경
  final double? windSpeed; // Nullable로 변경

  HourlyWeather({
    required this.dateTime,
    required this.temperature,
    required this.condition,
    this.humidity, // Nullable 필드로 변경
    this.windSpeed, // Nullable 필드로 변경
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000,
          isUtc: false), // UTC가 아닌 현재 시간대로 설정
      temperature: json['temp'].toDouble(),
      condition: json['weather'][0]['description'],
      humidity: json['humidity']?.toInt(), // 옵셔널 필드 처리
      windSpeed: json['wind_speed']?.toDouble(), // 옵셔널 필드 처리
    );
  }
}
