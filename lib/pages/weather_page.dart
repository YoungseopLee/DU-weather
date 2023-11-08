// weather_page.dart
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

  bool _isLoading = false; // 로딩 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadPlaceholderImage();
    _isLoading = false;
  }

  void _finishLoading() {
    setState(() {
      _isLoading = false;
    });
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
        'A ${weather.mainCondition} day with a temperature of ${weather.temperature}°C city or nature, boy or girl or both, ';
    String? messageId = await _nextLegApiService.generateImage(prompt);
    if (messageId != null) {
      print('messageId : $messageId');
      _nextLegApiService.pollForImage(messageId).then((imageBytes) {
        if (imageBytes != null) {
          print('imageBytes : $imageBytes');
          print('Received image data for background.');
          setState(() {
            _backgroundImage = imageBytes;
          });
        } else {
          print('No image data received, using placeholder.');
          setState(() {
            _backgroundImage = placeholderImageBytes;
          });
        }
      }).catchError((error) {
        print('An error occurred while polling for image: $error');
        setState(() {
          _backgroundImage = placeholderImageBytes;
        });
      });
    } else {
      print('No messageId received, cannot proceed to fetch image.');
      setState(() {
        _backgroundImage = placeholderImageBytes;
      });
    }
  }

  List<String> _imageUrls = ['assets/background/background-sunny05.png'];
  int _currentImageIndex = 0;

  // 이미지 URL 배열을 초기화하는 메소드 추가
  void _initializeImageUrls(List<String> urls) {
    setState(() {
      _imageUrls = urls;
    });
  }

  void _changeImage(int newIndex) {
    if (_imageUrls.isNotEmpty && newIndex < _imageUrls.length) {
      _nextLegApiService.getImageBytes(_imageUrls[newIndex]).then((imageBytes) {
        if (imageBytes != null) {
          setState(() {
            _backgroundImage = imageBytes;
            _currentImageIndex = newIndex;
          });
        }
      }).catchError((error) {
        print('An error occurred while fetching the image: $error');
      });
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
                    if (_isLoading) // 로딩 중이면 애니메이션 표시
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    // FloatingActionButton을 ElevatedButton으로 변경하고 이미지 변경 로직을 적용
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 10, bottom: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            int nextIndex =
                                (_currentImageIndex + 1) % _imageUrls.length;
                            _changeImage(nextIndex);
                            print('nextIndex : $nextIndex');
                          },
                          child: Text('이미지 변경'),
                        ),
                      ),
                    ),
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
