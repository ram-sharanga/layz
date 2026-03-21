import 'package:shared_preferences/shared_preferences.dart';

// ── Tooltip keys — add a new constant for every new tooltip ───────────────
// Never use raw strings elsewhere in the app — always reference these.

abstract class TooltipKeys {
  static const planTapDay        = 'tt_plan_tap_day';
  static const restTimer         = 'tt_rest_timer';
  static const personalRecord    = 'tt_personal_record';
  static const muscleVolume      = 'tt_muscle_volume';
  static const plateCalculator   = 'tt_plate_calculator';
  static const exerciseSubs      = 'tt_exercise_subs';
  static const supersetLink      = 'tt_superset_link';
  static const logSet            = 'tt_log_set';
}

// ── Service ───────────────────────────────────────────────────────────────

class TooltipService {
  static SharedPreferences? _prefs;

  // Call once at app start — or lazily before first use
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Returns true if this tooltip should be shown (first time only)
  static bool shouldShow(String key) {
    if (_prefs == null) return false;
    return !(_prefs!.getBool(key) ?? false);
  }

  // Call after showing the tooltip to mark it as seen
  static Future<void> markSeen(String key) async {
    await _prefs?.setBool(key, true);
  }

  // Convenience — check and mark in one call
  // Returns true if shown (first time), false if already seen
  static Future<bool> showOnce(String key) async {
    if (!shouldShow(key)) return false;
    await markSeen(key);
    return true;
  }

  // Dev only — reset all tooltips (useful during testing)
  static Future<void> resetAll() async {
    final keys = [
      TooltipKeys.planTapDay,
      TooltipKeys.restTimer,
      TooltipKeys.personalRecord,
      TooltipKeys.muscleVolume,
      TooltipKeys.plateCalculator,
      TooltipKeys.exerciseSubs,
      TooltipKeys.supersetLink,
      TooltipKeys.logSet,
    ];
    for (final k in keys) {
      await _prefs?.remove(k);
    }
  }
}