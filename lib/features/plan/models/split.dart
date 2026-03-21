// lib/features/plan/models/split.dart

// ── Enums ──────────────────────────────────────────────────────────────────

enum SplitType {
  pushPullLegs,
  upperLower,
  fullBody,
}

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  // Convert from DateTime.weekday (1=Mon, 7=Sun)
  // Static method lives here — identity logic belongs in the enum, not an extension
  static WeekDay fromDateTime(DateTime dt) {
    return WeekDay.values[dt.weekday - 1];
  }
}

// ── Extensions ─────────────────────────────────────────────────────────────

extension WeekDayLabel on WeekDay {
  String get short {
    switch (this) {
      case WeekDay.monday:    return 'Mon';
      case WeekDay.tuesday:   return 'Tue';
      case WeekDay.wednesday: return 'Wed';
      case WeekDay.thursday:  return 'Thu';
      case WeekDay.friday:    return 'Fri';
      case WeekDay.saturday:  return 'Sat';
      case WeekDay.sunday:    return 'Sun';
    }
  }

  String get full {
    switch (this) {
      case WeekDay.monday:    return 'Monday';
      case WeekDay.tuesday:   return 'Tuesday';
      case WeekDay.wednesday: return 'Wednesday';
      case WeekDay.thursday:  return 'Thursday';
      case WeekDay.friday:    return 'Friday';
      case WeekDay.saturday:  return 'Saturday';
      case WeekDay.sunday:    return 'Sunday';
    }
  }

}

extension SplitLabel on SplitType {
  String get name {
    switch (this) {
      case SplitType.pushPullLegs: return 'Push Pull Legs';
      case SplitType.upperLower:   return 'Upper Lower';
      case SplitType.fullBody:     return 'Full Body';
    }
  }

  String get description {
    switch (this) {
      case SplitType.pushPullLegs:
        return '3–6 days. Each session targets related muscles. '
            'Most popular split globally. Scales with you.';
      case SplitType.upperLower:
        return '4 days. Upper body and lower body alternate. '
            'Great balance of volume and recovery.';
      case SplitType.fullBody:
        return '2–3 days. Every session works everything. '
            'Best if time is limited.';
    }
  }

  // Auto-assign split based on goal
  static SplitType fromGoal(String goal) {
    switch (goal) {
      case 'muscle': return SplitType.pushPullLegs;
      case 'lean':   return SplitType.upperLower;
      case 'fit':    return SplitType.fullBody;
      default:       return SplitType.pushPullLegs;
    }
  }
}

// ── Schedule entry ─────────────────────────────────────────────────────────

class ScheduleDay {
  final WeekDay day;
  final String? routineName; // null = rest day
  final bool isCompleted;
  final bool isToday;

  const ScheduleDay({
    required this.day,
    this.routineName,
    this.isCompleted = false,
    this.isToday = false,
  });

  bool get isRest => routineName == null;

  ScheduleDay copyWith({
    String? routineName,
    bool? isCompleted,
    bool? isToday,
    bool setRest = false,
  }) {
    return ScheduleDay(
      day: day,
      routineName: setRest ? null : (routineName ?? this.routineName),
      isCompleted: isCompleted ?? this.isCompleted,
      isToday: isToday ?? this.isToday,
    );
  }
}

// ── Split generator ────────────────────────────────────────────────────────
// Pure function — takes a split type, returns a weekly schedule.
// No Supabase, no Flutter, just logic.

class SplitGenerator {

  static List<ScheduleDay> generate(SplitType split) {
    final today = WeekDay.fromDateTime(DateTime.now());

    final schedule = _buildSchedule(split);

    return WeekDay.values.map((day) {
      return ScheduleDay(
        day: day,
        routineName: schedule[day],
        isToday: day == today,
        // TODO: REMOVE AFTER UI TESTING
    isCompleted: day == WeekDay.monday || day == WeekDay.friday,
      );
    }).toList();
  }

  static Map<WeekDay, String?> _buildSchedule(SplitType split) {
    switch (split) {
      case SplitType.pushPullLegs:
        // Mon Push / Tue Pull / Wed Legs / Thu Rest / Fri Push / Sat Pull / Sun Rest
        return {
          WeekDay.monday:    'Push Day',
          WeekDay.tuesday:   'Pull Day',
          WeekDay.wednesday: 'Legs Day',
          WeekDay.thursday:  null,
          WeekDay.friday:    'Push Day',
          WeekDay.saturday:  'Pull Day',
          WeekDay.sunday:    null,
        };

      case SplitType.upperLower:
        // Mon Upper / Tue Lower / Wed Rest / Thu Upper / Fri Lower / Sat Rest / Sun Rest
        return {
          WeekDay.monday:    'Upper Body',
          WeekDay.tuesday:   'Lower Body',
          WeekDay.wednesday: null,
          WeekDay.thursday:  'Upper Body',
          WeekDay.friday:    'Lower Body',
          WeekDay.saturday:  null,
          WeekDay.sunday:    null,
        };

      case SplitType.fullBody:
        // Mon Full / Tue Rest / Wed Full / Thu Rest / Fri Full / Sat Rest / Sun Rest
        return {
          WeekDay.monday:    'Full Body',
          WeekDay.tuesday:   null,
          WeekDay.wednesday: 'Full Body',
          WeekDay.thursday:  null,
          WeekDay.friday:    'Full Body',
          WeekDay.saturday:  null,
          WeekDay.sunday:    null,
        };
    }
  }

  // Routine names for a given split — used to seed routines in Supabase
  static List<String> routineNamesFor(SplitType split) {
    switch (split) {
      case SplitType.pushPullLegs:
        return ['Push Day', 'Pull Day', 'Legs Day'];
      case SplitType.upperLower:
        return ['Upper Body', 'Lower Body'];
      case SplitType.fullBody:
        return ['Full Body'];
    }
  }
}