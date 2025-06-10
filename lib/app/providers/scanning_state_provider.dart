import 'package:flutter/material.dart';

enum ScanningMode {
  none,
  qr,
  nfc,
}

class ScanningStateProvider extends ChangeNotifier {
  ScanningMode _currentMode = ScanningMode.none;

  ScanningMode get currentMode => _currentMode;

  void startScanning(ScanningMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void stopScanning() {
    _currentMode = ScanningMode.none;
    notifyListeners();
  }
}