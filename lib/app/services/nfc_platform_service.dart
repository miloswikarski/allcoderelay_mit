import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class NfcPlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.grapph.allcoderelay/nfc',
  );

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod('isAvailable');
    } catch (e) {
      developer.log(
        'Error checking NFC availability: $e',
        name: 'NfcPlatformService',
      );
      return false;
    }
  }

  Future<void> startSession({required Function(String) onTagRead}) async {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onTagRead') {
          onTagRead(call.arguments as String);
        }
      });

      await _channel.invokeMethod('startSession');
    } catch (e) {
      developer.log(
        'Error starting NFC session: $e',
        name: 'NfcPlatformService',
      );
      throw e;
    }
  }

  Future<void> stopSession() async {
    try {
      await _channel.invokeMethod('stopSession');
      _channel.setMethodCallHandler(null);
    } catch (e) {
      developer.log(
        'Error stopping NFC session: $e',
        name: 'NfcPlatformService',
      );
      throw e;
    }
  }
}
