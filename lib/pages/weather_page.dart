import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/pages/weather_page_detail.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/service/thenextleg_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _weatherService =
      WeatherService('5e20005e73bc298e26fbb7d0a73fa48d');
  final NextLegApiService _nextLegApiService =
      NextLegApiService('3f84fe52-979b-4df2-a75a-0fcb138ac472');
  Weather? _weather;
  Uint8List? _backgroundImage;
  Uint8List? placeholderImageBytes;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadPlaceholderImage();
  }

  Future<void> _loadPlaceholderImage() async {
    final ByteData data =
        await rootBundle.load('assets/images/placeholder.png');
    placeholderImageBytes = data.buffer.asUint8List();
  }

  Future<void> _fetchWeather() async {
    try {
      Position position = await _weatherService.getCurrentLocation();
      Weather weather = await _weatherService.getWeather(
          position.latitude, position.longitude);
      setState(() => _weather = weather);
      await _updateBackgroundImage(weather);
      print("Weather data fetched successfully.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load weather data: $e')),
        );
      }
    }
  }

  Future<void> _updateBackgroundImage(Weather weather) async {
    String prompt =
        'A ${weather.mainCondition} day with a temperature of ${weather.temperature}°C girl or boy';
    String? messageId = await _nextLegApiService.generateImage(prompt);
    if (messageId != null) {
      Uint8List? imageBytes = await _nextLegApiService.pollForImage(messageId);
      if (imageBytes != null) {
        print('Received image data for background.');
        setState(() {
          _backgroundImage = imageBytes;
        });
      } else {
        print('No image data received, using placeholder.');
        setState(() {
          _backgroundImage =
              placeholderImageBytes; // Use the loaded placeholder image bytes
        });
      }
    } else {
      print('No messageId received, cannot proceed to fetch image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          // Main weather info page with background image
          Stack(
            children: [
              // Background image
              _backgroundImage != null
                  ? Image.memory(
                      _backgroundImage!,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      alignment: Alignment.center,
                    )
                  : const SizedBox(), // Placeholder for background image
              // Weather information
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_weather != null) ...[
                      Text('${_weather?.temperature?.round() ?? ""}°',
                          style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text(_weather?.mainCondition ?? "",
                          style: TextStyle(fontSize: 18, color: Colors.black)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Detailed weather info page
          if (_weather != null) DetailWeatherPage(weather: _weather!),
        ],
      ),
    );
  }
}
