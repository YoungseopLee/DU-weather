// lib/utils/image_saver.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ImageSaver {
  static Future<void> saveImageToGallery(Uint8List imageBytes) async {
    // 저장 권한 요청
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // 임시 디렉토리 경로 가져오기
      final directory = await getTemporaryDirectory();
      // 파일 경로 생성
      final imagePath = '${directory.path}/my_image.png';
      // 파일 저장
      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // 갤러리에 이미지 저장
      final result = await ImageGallerySaver.saveFile(imageFile.path);
      if (result["isSuccess"]) {
        print("Image saved to gallery");
      } else {
        print("Failed to save image");
      }
    } else {
      print("Storage permission is denied");
    }
  }
}
