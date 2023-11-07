// thenextleg_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NextLegApiService {
  final String _apiEndpoint = 'https://api.thenextleg.io/v2/imagine';
  final String _authToken;

  NextLegApiService(this._authToken);

  Future<String?> generateImage(String prompt,
      {String ref = '',
      String webhookOverride = '',
      bool ignorePrefilter = false}) async {
    var headers = {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };

    var requestBody = {
      'msg': prompt,
      'ref': ref,
      'webhookOverride': webhookOverride,
      'ignorePrefilter': ignorePrefilter.toString(),
    };

    var request = http.Request('POST', Uri.parse(_apiEndpoint));
    request.body = json.encode(requestBody);
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response =
          await request.send().timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        String body = await response.stream.bytesToString();
        var data = json.decode(body);
        if (data != null && data['messageId'] != null) {
          print('Image generation initiated successfully.');
          return data['messageId']; // Correct key for the messageId
        } else {
          print('The response did not contain a messageId.');
          return null;
        }
      } else {
        print(
            'Failed to initiate image generation. Status code: ${response.statusCode}.');
        return null;
      }
    } catch (e) {
      print('An exception occurred while generating image: $e');
      return null;
    }
  }

  // Helper method to fetch the image bytes from a given URL
  Future<Uint8List?> _getImageBytes(String imageUrl) async {
    var headers = {'Authorization': 'Bearer $_authToken'};
    var response = await http.get(Uri.parse(imageUrl), headers: headers);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print(
          'Failed to retrieve the image. Status code: ${response.statusCode}.');
      return null;
    }
  }

  Future<Uint8List?> pollForImage(String messageId,
      {int maxRetries = 20, int expireMins = 2}) async {
    var pollUrl =
        'https://api.thenextleg.io/v2/message/$messageId?expireMins=$expireMins';
    var headers = {'Authorization': 'Bearer $_authToken'};
    int retryCount = 0;

    while (retryCount < maxRetries) {
      var response = await http.get(Uri.parse(pollUrl), headers: headers);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data != null && data['progress'] != null) {
          int progress = data['progress'];
          print('Progress: $progress%');
          if (progress == 100) {
            // Here you print the full response if progress is 100%
            print('Full API response at 100% progress: ${json.encode(data)}');
            if (data['imageUrl'] != null) {
              print('Image URL: ${data['imageUrl']}'); // Log the image URL
              return await _getImageBytes(data['imageUrl']);
            } else {
              print('Progress is 100%, but no imageUrl is provided.');
              // You can handle the lack of an image URL as needed.
              break;
            }
          } else {
            print('Current progress: ${progress}%, retrying...');
          }
        } else {
          print('The response did not contain progress or imageUrl.');
          break;
        }
      } else {
        print('Failed to poll for image. Status code: ${response.statusCode}.');
        break;
      }

      await Future.delayed(Duration(seconds: 5));
      retryCount++;
    }

    print('Max retries exceeded or an error occurred.');
    return null;
  }

  Future<void> updateBackground(
      String imgUrl, Function(Uint8List) onImageRetrieved) async {
    try {
      var response = await http.get(
        Uri.parse(imgUrl),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('Image retrieved successfully.');
        onImageRetrieved(response.bodyBytes);
      } else {
        print(
            'Failed to retrieve the image. Status code: ${response.statusCode}.');
      }
    } catch (e) {
      print('An exception occurred while retrieving the image: $e');
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    // ... implementation of showErrorDialog
  }
}
