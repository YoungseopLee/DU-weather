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
    return 'No rain expected in the next 24 hours.\n'
        '\n--------------------------------------\n';
  }

  String get weatherAnimationPath =>
      _getWeatherAnimation(weather.mainCondition);

  String _getWeatherAnimation(String condition) {
    final bool isDayTime = DateTime.now().isAfter(weather.sunrise) &&
        DateTime.now().isBefore(weather.sunset);

    print(isDayTime);

    // 날씨 조건과 시간대에 맞는 애니메이션을 선택합니다.
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return isDayTime
            ? 'assets/icon/day-sunny.json'
            : 'assets/icon/night-sunny.json';

      case 'overcast clouds':
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
        return isDayTime
            ? 'assets/icon/day-cloud.json'
            : 'assets/icon/night-cloud.json';

      case 'rain':
      case 'light rain':
      case 'heavy intensity rain':
        return isDayTime
            ? 'assets/icon/day-rain.json'
            : 'assets/icon/night-rain.json';

      case 'thunderstorm':
        return isDayTime
            ? 'assets/icon/day-thunder.json'
            : 'assets/icon/night-thunder.json';

      case 'mist':
        return isDayTime
            ? 'assets/icon/day-mist.json'
            : 'assets/icon/night-mist.json';

      case 'snow':
        return isDayTime
            ? 'assets/icon/day-snow.json'
            : 'assets/icon/night-snow.json';

      default:
        return isDayTime
            ? 'assets/icon/day-sunny.json'
            : 'assets/icon/night-sunny.json';
    }
  }

  Widget _weatherAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Lottie.asset(weatherAnimationPath,
          width: 240, height: 240, fit: BoxFit.fill),
    );
  }

  // 도시 날씨 정보 위젯
  Widget _cityWeatherInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(
        weather.cityName,
        style: Theme.of(context).textTheme.headline4?.copyWith(
            color: Colors.black54, fontWeight: FontWeight.w500), // 볼드 스타일 적용
      ),
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
      'H:${todayWeather.maxTemperature.round()}° L:${todayWeather.minTemperature.round()}° \n',
      style: const TextStyle(fontSize: 15),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isDayTime(DateTime dateTime) {
    // 날출 시간을 오전 6시, 날질 시간을 오후 6시로 가정하거나 실제 날씨 데이터에서 시간을 가져옵니다
    DateTime sunrise = DateTime(dateTime.year, dateTime.month, dateTime.day, 6);
    DateTime sunset = DateTime(dateTime.year, dateTime.month, dateTime.day, 18);
    return dateTime.isAfter(sunrise) && dateTime.isBefore(sunset);
  }

  // 메인 온도 정보 위젯
  Widget _mainTemperatureInfo(BuildContext context) {
    final currentWeather = weather.hourly.first;
    return Column(
      children: [
        Text(
          '${currentWeather.temperature.round()}°',
          style: Theme.of(context)
              .textTheme
              .headline1
              ?.copyWith(color: Colors.black87),
        ),
        Text(
          'H:${weather.maxTemperature.round()}° L:${weather.minTemperature.round()}°',
          style: Theme.of(context)
              .textTheme
              .subtitle1
              ?.copyWith(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _rainForecast() {
    return Text(
      rainForecastMessage,
      style: TextStyle(fontSize: 18, color: Colors.black87),
    );
  }

  Widget _hourlyForecast() {
    final now = DateTime.now();
    // 현재 시간에 가장 가까운 HourlyWeather 객체의 인덱스를 찾습니다.
    int startIndex = weather.hourly.indexWhere(
        (h) => h.dateTime.isAtSameMomentAs(now) || h.dateTime.isAfter(now));

    // endIndex를 현재 시간으로부터 12시간 후로 설정합니다.
    int endIndex = startIndex + 12; // 12시간 후의 인덱스

    // endIndex가 리스트 범위를 벗어나지 않게 조정합니다.
    endIndex =
        (endIndex >= weather.hourly.length) ? weather.hourly.length : endIndex;

    // 현재 시간부터 12시간 이후까지의 HourlyWeather 객체들을 가져옵니다.
    final hourlyForecastWidgets = weather.hourly
        .getRange(startIndex, endIndex + 1)
        .map((hourlyWeather) => _hourlyWeatherInfo(hourlyWeather))
        .toList();

    return SizedBox(
      height: 100.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecastWidgets.length,
        itemBuilder: (context, index) => hourlyForecastWidgets[index],
      ),
    );
  }

  Widget _hourlyWeatherInfo(HourlyWeather hourlyWeather) {
    bool isDayTime = hourlyWeather.dateTime.isAfter(weather.sunrise) &&
        hourlyWeather.dateTime.isBefore(weather.sunset);
    String iconName = _getWeatherIcon(hourlyWeather, isDayTime);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(DateFormat('ha').format(hourlyWeather.dateTime)),
          Lottie.asset(iconName, width: 50, height: 50),
          Text('${hourlyWeather.temperature.round()}°'),
        ],
      ),
    );
  }

  Widget _combinedForecast(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.01), // 투명도 설정
        borderRadius: BorderRadius.circular(50), // 모서리 둥글게
      ),
      child: Column(
        children: [
          _rainForecast(),
          _hourlyForecast(), // 이미 정의되어 있는 _hourlyForecast() 위젯 사용
        ],
      ),
    );
  }

  String _getWeatherIcon(HourlyWeather hourlyWeather, bool isDayTime) {
    final bool isDayTime = hourlyWeather.dateTime.isAfter(weather.sunrise) &&
        hourlyWeather.dateTime.isBefore(weather.sunset);

    // 날씨 조건과 시간대에 맞는 애니메이션을 선택합니다.
    switch (hourlyWeather.condition.toLowerCase()) {
      case 'clear sky':
        return isDayTime
            ? 'assets/icon/day-sunny.json'
            : 'assets/icon/night-sunny.json';

      case 'overcast clouds':
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
        return isDayTime
            ? 'assets/icon/day-cloud.json'
            : 'assets/icon/night-cloud.json';

      case 'rain':
      case 'light rain':
      case 'heavy intensity rain':
        return isDayTime
            ? 'assets/icon/day-rain.json'
            : 'assets/icon/night-rain.json';

      case 'thunderstorm':
        return isDayTime
            ? 'assets/icon/day-thunder.json'
            : 'assets/icon/night-thunder.json';

      case 'mist':
        return isDayTime
            ? 'assets/icon/day-mist.json'
            : 'assets/icon/night-mist.json';

      case 'snow':
        return isDayTime
            ? 'assets/icon/day-snow.json'
            : 'assets/icon/night-snow.json';

      default:
        return isDayTime
            ? 'assets/icon/day-sunny.json'
            : 'assets/icon/night-sunny.json';
    }
  }

  Widget _dailyForecast() {
    var now = DateTime.now();
    var startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // 주의 시작을 월요일로 설정
    var endOfWeek = startOfWeek.add(Duration(days: 6)); // 일주일의 끝을 일요일로 설정

    List<Widget> weekForecast = weather.daily
        .where((d) =>
            d.dateTime.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            d.dateTime.isBefore(endOfWeek.add(Duration(days: 1))))
        .map((dailyWeather) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0), // 각 Row 사이의 간격 조정
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('E').format(dailyWeather.dateTime),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: _weatherIcon(
                        dailyWeather.condition,
                        isDayTime(dailyWeather.dateTime),
                        dailyWeather.precipitationChance?.toDouble() ?? 0.0),
                  ),
                  Expanded(
                    child: Text(
                      '${dailyWeather.precipitationChance ?? 0}%', // 강수 확률이 없을 경우 0%로 표시
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${dailyWeather.minTemperature.round()}°',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${dailyWeather.maxTemperature.round()}°',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ))
        .toList();

    return Container(
      padding: EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54.withOpacity(0.01), // 투명도 설정
        borderRadius: BorderRadius.circular(50), // 모서리 둥글게
      ),
      child: Column(
        children: weekForecast,
      ),
    );
  }

  Widget _weatherIcon(
      String condition, bool isDayTime, double precipitationChance) {
    // 강수 확률이 0이 아닌 경우 비에 관련된 Lottie 애니메이션을 표시합니다.
    String iconName;
    if (precipitationChance > 0) {
      iconName = isDayTime
          ? 'assets/icon/day-rain.json'
          : 'assets/icon/night-rain.json';
    } else {
      iconName = _WeatherIcon(condition, isDayTime);
    }

    return Lottie.asset(
      iconName,
      width: 45,
      height: 45,
    );
  }

  String _WeatherIcon(String condition, bool isDayTime) {
    // 날씨 상태와 시간에 따라 애니메이션 경로를 결정합니다

    final bool isDayTime = DateTime.now().isAfter(weather.sunrise) &&
        DateTime.now().isBefore(weather.sunset);
    switch (condition.toLowerCase()) {
      case 'clear sky':
        return isDayTime
            ? 'assets/icon/day-sunny.json'
            : 'assets/icon/night-sunny.json';
      case 'rain':
        return isDayTime
            ? 'assets/icon/day-rain.json'
            : 'assets/icon/night-rain.json';
      // 필요에 따라 더 많은 케이스를 추가합니다
      default:
        return 'assets/icon/day-sunny.json'; // 기본 애니메이션
    }
  }

  // 현재 시간을 기준으로 가장 가까운 정각 시간으로 내림하는 함수
  DateTime roundDownToTheHour(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour);
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top + 25;
    final currentHour = roundDownToTheHour(DateTime.now());
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: paddingTop + 25),
            _cityWeatherInfo(context),
            _weatherAnimation(),
            Text(
              '${weather.mainCondition} / ${weather.temperature}°\n', // 현재 날씨 상태를 표시합니다.
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            _temperatureInfo(),
            _combinedForecast(context),
            _dailyForecast(),
          ],
        ),
      ),
    );
  }
}
