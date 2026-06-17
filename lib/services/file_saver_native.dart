import 'dart:io';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.pindou.app/gallery');

Future<String> saveFileToDownloads(Uint8List bytes, String filename) async {
  if (Platform.isAndroid) {
    return await _saveToAndroidGallery(bytes, filename);
  } else {
    return await _saveToDesktop(bytes, filename);
  }
}

Future<String> _saveToAndroidGallery(Uint8List bytes, String filename) async {
  try {
    final result = await _channel.invokeMethod<String>('saveToGallery', {
      'bytes': bytes,
      'filename': filename,
    });
    return result ?? '已保存到相册';
  } on MissingPluginException {
    // Fallback: save to app cache and notify user
    return await _saveToDesktop(bytes, filename);
  }
}

Future<String> _saveToDesktop(Uint8List bytes, String filename) async {
  String dirPath;
  if (Platform.isAndroid) {
    // Fallback for Android if MediaStore fails
    dirPath = '/storage/emulated/0/Download';
  } else {
    dirPath = '${Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.'}/Pictures/酥豆';
  }

  final dir = Directory(dirPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final file = File('$dirPath/$filename');
  await file.writeAsBytes(bytes);
  return '已保存: ${file.path}';
}
