// lib/features/plan/services/tooltip_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class TooltipService {
  static const _prefix = 'tooltip_shown_';

  static Future<bool> hasShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key') ?? false;
  }

  static Future<void> markShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', true);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) await prefs.remove(k);
  }
}