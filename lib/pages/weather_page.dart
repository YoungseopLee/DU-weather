// weather_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/pages/weather_page_detail.dart';
import 'package:weather/service/weather_service.dart';
import 'package:weather/service/thenextleg_service.dart';
import 'package:weather/utils/image_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  List<Uint8List?> _backgroundImages = [];
  int _currentImageIndex = 0;

  bool _isLoading = false; // 로딩 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _loadSavedImageIndex();
    _fetchWeather();
    _loadPlaceholderImage();
    _isLoading = false;
  }

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

  Future<void> _loadPlaceholderImage() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/images/placeholder.png');
      setState(() {
        placeholderImageBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      print('Placeholder image could not be loaded: $e');
    }
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
    _startLoading(); // 로딩 시작

    // intl 패키지를 사용하여 날짜와 시간 형식을 지정합니다.
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final currentTime = dateFormat.format(DateTime.now());

    String prompt = '${currentTime}'
        '${weather.mainCondition} '
        '${weather.temperature} '
        '${weather.cityName} '
        'with city and nature '
        'modern animation style style '
        'I wish people(A handsome guy or beautiful woman appears) were located a little farther away.';

    String? messageId = await _nextLegApiService.generateImage(prompt);
    if (messageId != null) {
      print('messageId : $messageId');
      var imagesList = await _nextLegApiService.pollForImages(messageId);
      if (imagesList.isNotEmpty) {
        print('Received image data for background.');
        setState(() {
          _backgroundImages = imagesList;
          _backgroundImage = _backgroundImages.first; // 첫 번째 이미지를 기본 배경으로 설정
        });
      } else {
        print('No image data received, using placeholder.');
        setState(() {
          _backgroundImage = placeholderImageBytes;
        });
      }
    } else {
      print('No messageId received, cannot proceed to fetch image.');
      setState(() {
        _backgroundImage = placeholderImageBytes;
      });
    }

    _finishLoading();
  }

  int currentImageIndex = 0;

  void _changeBackgroundImage() {
    if (_backgroundImages.isNotEmpty) {
      // 이미지 리스트가 비어 있지 않다면 다음 이미지로 변경
      setState(() {
        _currentImageIndex =
            (_currentImageIndex + 1) % _backgroundImages.length;
        _backgroundImage = _backgroundImages[_currentImageIndex];
      });
      _saveImageIndex(_currentImageIndex); // 인덱스를 저장합니다.
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/saved_image.png');
  }

  Future<File> _saveImage(Uint8List imageBytes) async {
    final file = await _localFile;
    return file.writeAsBytes(imageBytes);
  }

// 이미지 저장 메소드
  void _saveImageToFile() async {
    if (_backgroundImage != null) {
      final result = await ImageGallerySaver.saveImage(_backgroundImage!);
      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지가 갤러리에 저장되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 저장에 실패했습니다.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장할 이미지가 없습니다.')),
      );
    }
  }

  // 저장된 이미지 인덱스를 로드합니다.
  Future<void> _loadSavedImageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('saved_image_index') ?? 0;
    setState(() {
      _currentImageIndex = savedIndex;
      // 이전에 저장된 인덱스를 사용하여 배경 이미지를 설정할 수 있습니다.
      // 예: _backgroundImage = _backgroundImages[_currentImageIndex];
    });
  }

  // 선택된 이미지 인덱스를 저장합니다.
  Future<void> _saveImageIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_image_index', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(children: [
      Stack(
        children: [
          // 배경 이미지 및 로딩 로직
          ..._buildBackgroundAndLoadingUI(),
          // 날씨 정보
          if (!_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 40,
              child: _weatherInfoWidget(),
            ),

          // 이미지 교체 버튼
          if (!_isLoading)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _changeBackgroundImage,
                child: Icon(Icons.image),
              ),
            ),

          // 이미지 재생성 요청 버튼
          if (!_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: _requestNewImage,
                backgroundColor: Colors.blue,
                child: Icon(Icons.refresh),
              ),
            ),

          // 이미지 저장 버튼 - 상단 여백 추가
          if (_backgroundImage != null && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20, // 상단에 여백 추가
              right: 20,
              child: FloatingActionButton(
                onPressed: _saveImageToFile, // _saveImageToFile 메소드 호출
                backgroundColor: Colors.green,
                child: Icon(Icons.save_alt),
              ),
            ),
        ],
      ),
      // 상세 날씨 정보 페이지
      if (_weather != null) DetailWeatherPage(weather: _weather!),
    ]));
  }

  void _requestNewImage() {
    // 이미지 재생성을 위한 메소드
    _startLoading();
    setState(() {
      // 배경 이미지를 placeholder로 설정
      _backgroundImage = placeholderImageBytes;
    });
    // 새로운 배경 이미지 요청
    _fetchWeather();
  }

  List<Widget> _buildBackgroundAndLoadingUI() {
    // 배경 이미지와 로딩 애니메이션을 위한 위젯 리스트를 반환하는 메소드
    return [
      _backgroundImage != null
          ? Image.memory(
              _backgroundImage!,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
            )
          : placeholderImageBytes != null
              ? Image.memory(
                  placeholderImageBytes!,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                )
              : Center(child: CircularProgressIndicator()), // 로딩 플레이스홀더

      if (_isLoading)
        Center(
          child: Lottie.asset(
            'assets/background/image_loading.json',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
        ),
    ];
  }

  Widget _weatherInfoWidget() {
    // 날씨 정보를 표시하는 위젯
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_weather != null) ...[
          Text('${_weather!.temperature.round()}°',
              style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          Text(_weather!.mainCondition,
              style: TextStyle(fontSize: 18, color: Colors.black)),
        ],
      ],
    );
  }
}
