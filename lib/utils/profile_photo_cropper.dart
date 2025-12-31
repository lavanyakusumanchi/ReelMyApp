import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilePhotoCropper {
  static Future<File?> cropImage(BuildContext context, File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      // cropStyle: CropStyle.circle, // Removed as it caused build error in this version
      compressQuality: 100, // Maintain quality
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Move and Scale',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: [CropAspectRatioPreset.square], // Force square only
          lockAspectRatio: true,
          hideBottomControls: true, // Hide extra controls for pure pan/zoom experience
          showCropGrid: false, 
          // circleDimmedLayer: true, // Removed as it caused build error
          dimmedLayerColor: Colors.black.withOpacity(0.9), // Darker dim
          cropFrameColor: Colors.transparent,
          cropGridColor: Colors.transparent,
          activeControlsWidgetColor: const Color(0xFF00D9FF),
        ),
        IOSUiSettings(
          title: 'Edit Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          rectHeight: 1080,
          rectWidth: 1080,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}
