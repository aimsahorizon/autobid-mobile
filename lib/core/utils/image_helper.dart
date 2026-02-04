import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class ImageHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from the specified source
  static Future<File?> pickImage({
    required ImageSource source,
    int quality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (file == null) return null;
      return File(file.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Crop an image file
  static Future<File?> cropImage({
    required File file,
    CropStyle cropStyle = CropStyle.rectangle,
    String title = 'Crop Image',
  }) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: title,
          ),
        ],
      );
      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }
}
