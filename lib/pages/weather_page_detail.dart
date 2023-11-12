// weather_page_detail.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/models/weather_model.dart';
import 'package:intl/intl.dart';

class DetailWeatherPage extends StatelessWidget {
  final Weather weather;

  DetailWeatherPage({required this.weather});

  String get rainForecastMessage {
    // 'rainForecastMessage'로 변경하여 변수처럼 사용합니다.
    final next24Hours = DateTime.now().add(const Duration(hours: 24));
    for (var hourlyWeather in weather.hourly) {
      if (hourlyWeather.dateTime.isBefore(next24Hours) &&
          hourlyWeather.condition.toLowerCase().contains('rain')) {
        return 'Rainy conditions expected around ${DateFormat('ha').format(hourlyWeather.dateTime)}.';
      }
    }
    return 'No rain expected in the next 24 hours.';
  }

  String get weatherAnimationPath =>
      _getWeatherAnimation(weather.mainCondition);

  static String _getWeatherAnimation(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return 'assets/images/day-sunny.json';

      case 'overcast clouds':
        return 'assets/images/day-cloud.json';
      case 'few clouds':
        return 'assets/images/day-cloud.json';
      case 'scattered clouds':
        return 'assets/images/day-cloud.json';
      case 'broken clouds':
        return 'assets/images/day-cloud.json';

      case 'rain':
        return 'assets/images/day-rain.json';
      case 'light rain':
        return 'assets/images/day-rain.json';
      case 'heavy intensity rain':
        return 'assets/images/day-rain.json';

      case 'thunderstorm':
        return 'assets/images/day-thunder.json';
      default:
        return 'assets/images/day-sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top + 30;
    final currentHour = DateTime.now().roundDown();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: paddingTop + 10),
            _cityWeatherInfo(context),
            _weatherAnimation(),
            Text(
              '현재 날씨: ${weather.mainCondition}', // 현재 날씨 상태를 표시합니다.
              style: const TextStyle(fontSize: 14),
            ),
            _temperatureInfo(),
            _rainForecast(),
            _hourlyForecast(currentHour),
            _dailyForecast(),
          ],
        ),
      ),
    );
  }

  Widget _cityWeatherInfo(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Text(weather.cityName,
                style: Theme.of(context).textTheme.headline4),
            Text('${weather.temperature.round()}°',
                style: Theme.of(context).textTheme.headline1),
          ],
        ),
      ),
    );
  }

  Widget _weatherAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Lottie.asset(weatherAnimationPath,
          width: 240, height: 240, fit: BoxFit.fill),
    );
  }

  Widget _temperatureInfo() {
    // 현재 날짜를 가져옵니다.
    DateTime now = DateTime.now();
    // 현재 날짜에 해당하는 DailyWeather 객체를 찾습니다.
    DailyWeather todayWeather = weather.daily.firstWhere(
      (d) => isSameDay(d.dateTime, now),
      orElse: () => weather.daily.first, // 만약 오늘의 날씨 데이터가 없다면 리스트의 첫 번째 데이터를 사용
    );

    return Text(
      'H:${todayWeather.maxTemperature.round()}° L:${todayWeather.minTemperature.round()}°',
      style: const TextStyle(fontSize: 16),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _rainForecast() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Text(
        rainForecastMessage,
        style: TextStyle(fontSize: 18, color: Colors.blueAccent),
      ),
    );
  }

  Widget _hourlyForecast(DateTime currentHour) {
    int startIndex =
        weather.hourly.indexWhere((h) => h.dateTime.isAfter(currentHour));
    // startIndex가 -1일 경우 0으로 설정하여 에러를 방지합니다.
    startIndex = max(startIndex, 0);

    final hourlyForecastWidgets = weather.hourly
        .sublist(startIndex, min(startIndex + 24, weather.hourly.length))
        .map((hourlyWeather) => _hourlyWeatherInfo(hourlyWeather))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SizedBox(
        height: 120.0,
        child: ListView(
            scrollDirection: Axis.horizontal, children: hourlyForecastWidgets),
      ),
    );
  }

  Widget _hourlyWeatherInfo(HourlyWeather hourlyWeather) {
    String iconName = _getWeatherIcon(hourlyWeather.condition);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(DateFormat('ha').format(hourlyWeather.dateTime)),
          Lottie.asset(iconName, width: 50, height: 50), // 날씨 아이콘 추가
          Text('${hourlyWeather.temperature.round()}°'),
        ],
      ),
    );
  }

  String _getWeatherIcon(String condition) {
    // 여기서는 간단한 조건에 따라 다른 Lottie 파일을 반환합니다.
    // 'condition' 변수를 분석하여 상황에 맞는 Lottie 애니메이션 파일을 선택해야 합니다.
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return 'assets/icon/day-sunny.json';
      case 'few clouds':
        return 'assets/icon/day-cloud.json';
      case 'scattered clouds':
        return 'assets/icon/day-cloud.json';
      case 'broken clouds':
        return 'assets/icon/day-cloud.json';
      case 'rain':
        return 'assets/icon/day-rain.json';
      case 'light rain':
        return 'assets/icon/day-rain.json';
      case 'thunderstorm':
        return 'assets/icon/day-thunder.json';
      // 추가적인 날씨 조건에 대한 아이콘을 여기에 추가할 수 있습니다.
      default:
        return 'assets/icon/day-sunny.json';
    }
  }

  Widget _dailyForecast() {
    final dailyForecastWidgets = weather.daily
        .map((dailyWeather) => ListTile(
              title: Text(DateFormat('E').format(dailyWeather.dateTime)),
              subtitle: Text(
                  '최고: ${dailyWeather.maxTemperature.round()}° 최저: ${dailyWeather.minTemperature.round()}°'),
            ))
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text('7-DAY FORECAST', style: TextStyle(fontSize: 18)),
        ),
        ...dailyForecastWidgets,
      ],
    );
  }
}

extension on DateTime {
  DateTime roundDown({int roundToNearestMinute = 60}) {
    // 'DateTime' 확장하여 날짜를 정시로 반올림하는 함수
    if (this.minute < 30) {
      return DateTime(year, month, day, hour);
    } else {
      return DateTime(year, month, day, hour + 1);
    }
  }
}
