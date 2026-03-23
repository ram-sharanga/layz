// lib/features/plan/models/split.dart

enum SplitType { pushPullLegs, upperLower, fullBody, arnoldSplit }

enum SplitLabel {
  pushPullLegs, upperLower, fullBody;

  static SplitLabel fromGoal(String goal) {
    switch (goal) {
      case 'muscle': return SplitLabel.pushPullLegs;
      case 'lean':   return SplitLabel.fullBody;
      case 'fit':    return SplitLabel.upperLower;
      default:       return SplitLabel.pushPullLegs;
    }
  }
}

enum WeekDay {
  monday, tuesday, wednesday, thursday, friday, saturday, sunday;

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

  static WeekDay fromDateTime(DateTime dt) {
    // DateTime.weekday: 1=Mon … 7=Sun
    return WeekDay.values[dt.weekday - 1];
  }
}

class ScheduleDay {
  final WeekDay day;
  final String? routineName;
  final bool    isCompleted;

  const ScheduleDay({
    required this.day,
    this.routineName,
    this.isCompleted = false,
  });

  bool get isRest => routineName == null;

  bool get isToday => day == WeekDay.fromDateTime(DateTime.now());

  ScheduleDay copyWith({
    String?  routineName,
    bool?    isCompleted,
    bool     setRest = false,
  }) {
    return ScheduleDay(
      day:          this.day,
      routineName:  setRest ? null : (routineName ?? this.routineName),
      isCompleted:  isCompleted ?? this.isCompleted,
    );
  }
}

class SplitGenerator {
  /// Returns ordered ScheduleDay list for a given split label.
  static List<ScheduleDay> generate(SplitLabel label) {
    switch (label) {
      case SplitLabel.pushPullLegs:
        return [
          const ScheduleDay(day: WeekDay.monday,    routineName: 'Push Day'),
          const ScheduleDay(day: WeekDay.tuesday,   routineName: 'Pull Day'),
          const ScheduleDay(day: WeekDay.wednesday, routineName: 'Legs Day'),
          const ScheduleDay(day: WeekDay.thursday),
          const ScheduleDay(day: WeekDay.friday,    routineName: 'Push Day'),
          const ScheduleDay(day: WeekDay.saturday,  routineName: 'Pull Day'),
          const ScheduleDay(day: WeekDay.sunday),
        ];
      case SplitLabel.upperLower:
        return [
          const ScheduleDay(day: WeekDay.monday,    routineName: 'Upper Body'),
          const ScheduleDay(day: WeekDay.tuesday,   routineName: 'Lower Body'),
          const ScheduleDay(day: WeekDay.wednesday),
          const ScheduleDay(day: WeekDay.thursday,  routineName: 'Upper Body'),
          const ScheduleDay(day: WeekDay.friday,    routineName: 'Lower Body'),
          const ScheduleDay(day: WeekDay.saturday),
          const ScheduleDay(day: WeekDay.sunday),
        ];
      case SplitLabel.fullBody:
        return [
          const ScheduleDay(day: WeekDay.monday,    routineName: 'Full Body A'),
          const ScheduleDay(day: WeekDay.tuesday),
          const ScheduleDay(day: WeekDay.wednesday, routineName: 'Full Body B'),
          const ScheduleDay(day: WeekDay.thursday),
          const ScheduleDay(day: WeekDay.friday,    routineName: 'Full Body A'),
          const ScheduleDay(day: WeekDay.saturday),
          const ScheduleDay(day: WeekDay.sunday),
        ];
    }
  }

  /// Returns unique routine names used by a split (for listing in My Routines).
  static List<String> routineNamesFor(SplitLabel label) {
    final schedule = generate(label);
    final seen     = <String>{};
    final result   = <String>[];
    for (final sd in schedule) {
      if (sd.routineName != null && seen.add(sd.routineName!)) {
        result.add(sd.routineName!);
      }
    }
    return result;
  }
}