import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._();
  static VibrationService get instance => _instance;
  VibrationService._();

  bool _enabled = true;
  bool get isEnabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('vibration_enabled') ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
  }

  void vibrate() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void vibrateLight() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void vibrateHeavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
