import 'dart:async';
import 'package:flutter/services.dart';

class IntentService {
  IntentService._();
  static final IntentService instance = IntentService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.ebook_app/file_channel');

  void Function(String filePath)? onPdfOpened;

  void initialize(void Function(String filePath) callback) {
    onPdfOpened = callback;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPdfOpened') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          onPdfOpened?.call(path);
        }
      }
    });
  }

  Future<String?> getInitialPdf() async {
    try {
      final String? path = await _channel.invokeMethod<String>('getInitialPdf');
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> openDefaultAppSettings() async {
    try {
      final bool? result =
          await _channel.invokeMethod<bool>('openDefaultAppSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
