// lib/features/plan/screens/schedule_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';
import 'package:layz/features/plan/models/routine.dart';
import 'package:layz/features/plan/models/split.dart';
import 'package:layz/features/plan/screens/create_routine_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Schedule editor — assign routines to days
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleEditorScreen extends StatefulWidget {
  const ScheduleEditorScreen({
    super.key,
    required this.goal,
    required this.userId,
    required this.initialSchedule,
    required this.availableRoutines,
  });

  final String            goal;
  final String            userId;
  final List<ScheduleDay> initialSchedule;
  final List<Routine>     availableRoutines;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  late List<ScheduleDay> _schedule;
  late List<Routine>     _routines;

  @override
  void initState() {
    super.initState();
    _schedule = List.from(widget.initialSchedule);
    _routines = List.from(widget.availableRoutines);
  }

  void _assignDay(int dayIdx, String? routineName) {
    HapticFeedback.selectionClick();
    setState(() {
      _schedule[dayIdx] = _schedule[dayIdx].copyWith(
        routineName: routineName,
        setRest: routineName == null,
      );
    });
  }

  void _openDayPicker(int dayIdx) {
    final sd = _schedule[dayIdx];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayAssignSheet(
        day:              sd.day,
        currentRoutine:   sd.routineName,
        routines:         _routines,
        onAssign:         (name) => _assignDay(dayIdx, name),
        onSetRest:        ()    => _assignDay(dayIdx, null),
        onCreateRoutine:  ()    => _openCreateRoutine(dayIdx),
      ),
    );
  }

  Future<void> _openCreateRoutine(int dayIdx) async {
    Navigator.of(context).pop(); // close sheet first
    final result = await Navigator.of(context).push<Routine>(
      MaterialPageRoute(
        builder: (_) => CreateRoutineScreen(
          goal:   widget.goal,
          userId: widget.userId,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _routines.add(result);
        _schedule[dayIdx] = _schedule[dayIdx].copyWith(routineName: result.name);
      });
    }
  }

  void _saveAndPop() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop({
      'schedule': _schedule,
      'routines': _routines,
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Edit Schedule',
                      style: GoogleFonts.dmSans(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, letterSpacing: -0.5,
                      )),
                ),
                GestureDetector(
                  onTap: _saveAndPop,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        )),
                  ),
                ),
              ],
            ),
          ),

          // ── Week days ────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _schedule.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final sd = _schedule[i];
                final today = WeekDay.fromDateTime(DateTime.now());
                final isToday = sd.day == today;

                return GestureDetector(
                  onTap: () => _openDayPicker(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isToday
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Day indicator
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(sd.day.short.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: isToday
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    letterSpacing: 1,
                                  )),
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4, height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: sd.isRest
                              ? Text('Rest day',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15, fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sd.routineName!,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        )),
                                    if (_routines.any((r) => r.name == sd.routineName))
                                      Text(
                                        () {
                                          final r = _routines.firstWhere(
                                              (r) => r.name == sd.routineName);
                                          return '${r.exerciseCount} exercises · ${r.estimatedLabel}';
                                        }(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12, color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.15)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day assign bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DayAssignSheet extends StatelessWidget {
  const _DayAssignSheet({
    required this.day,
    required this.currentRoutine,
    required this.routines,
    required this.onAssign,
    required this.onSetRest,
    required this.onCreateRoutine,
  });

  final WeekDay         day;
  final String?         currentRoutine;
  final List<Routine>   routines;
  final ValueChanged<String> onAssign;
  final VoidCallback    onSetRest;
  final VoidCallback    onCreateRoutine;

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bot + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          Text(day.full,
              style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 4),
          Text('Select a routine or set as rest',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Rest option
          _SheetRow(
            label: 'Rest day',
            icon: Icons.bedtime_outlined,
            isSelected: currentRoutine == null,
            isRest: true,
            onTap: () {
              onSetRest();
              Navigator.of(context).pop();
            },
          ),

          if (routines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('YOUR ROUTINES',
                style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 2.5,
                )),
            const SizedBox(height: 8),
            ...routines.map((r) => _SheetRow(
              label:      r.name,
              sublabel:   '${r.exerciseCount} exercises · ${r.estimatedLabel}',
              isSelected: currentRoutine == r.name,
              onTap: () {
                onAssign(r.name);
                Navigator.of(context).pop();
              },
            )),
          ],

          const SizedBox(height: 8),
          // Create new
          GestureDetector(
            onTap: onCreateRoutine,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.add, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Text('Create new routine',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    this.sublabel,
    this.icon,
    required this.isSelected,
    this.isRest = false,
    required this.onTap,
  });
  final String     label;
  final String?    sublabel;
  final IconData?  icon;
  final bool       isSelected;
  final bool       isRest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isRest
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.accent.withValues(alpha: 0.08))
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isRest
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.accent.withValues(alpha: 0.3))
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isSelected && !isRest
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      )),
                  if (sublabel != null)
                    Text(sublabel!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textSecondary,
                        )),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isRest
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    size: 12,
                    color: isRest ? AppColors.textPrimary : AppColors.background),
              ),
          ],
        ),
      ),
    );
  }
}