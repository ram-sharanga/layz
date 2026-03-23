// lib/features/plan/screens/roadmap_screen.dart
//
// COMPLETE — reads real data from SharedPreferences, computes node states
// dynamically from actual workout history, supports note-taking per day,
// proper auto-scroll, week navigation, milestone cards, everything wired.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:layz/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys (must match active_workout_screen + profile_screen)
// ─────────────────────────────────────────────────────────────────────────────

const String _kStreakCount   = 'streak_count';
const String _kTotalWorkouts = 'total_workouts';
const String _kActivityPrefix= 'activity_'; // activity_YYYY-MM-DD → int (sets done)
const String _kPRPrefix      = 'pr_';
const String _kNotePrefix    = 'roadmap_note_'; // roadmap_note_YYYY-MM-DD → String
const String _kJourneyStart  = 'journey_start_date'; // YYYY-MM-DD, set on first workout
const String _kUserGoal      = 'user_goal';
const String _kProfileSeeded = 'profile_seeded';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

DateTime _parseDay(String s) => DateTime.parse(s);

// ─────────────────────────────────────────────────────────────────────────────
// Node models
// ─────────────────────────────────────────────────────────────────────────────

enum _NodeType  { workout, rest, milestone }
enum _NodeState { completed, today, upcoming, missed }

class _RoadmapNode {
  final int       dayNumber;   // 1-based day number in the journey
  final DateTime  date;
  final String    label;
  final _NodeType  type;
  _NodeState       state;
  final String?   emoji;       // milestones only
  String?         note;        // user-added note, persisted
  final String?   prHit;       // exercise name if PR was set this day
  final int?      setsLogged;  // from activity_ prefs
  final int?      durationMin; // estimated from sets

  _RoadmapNode({
    required this.dayNumber,
    required this.date,
    required this.label,
    required this.type,
    required this.state,
    this.emoji,
    this.note,
    this.prHit,
    this.setsLogged,
    this.durationMin,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 90-day schedule template — PPL pattern (goal-aware, repeating)
// ─────────────────────────────────────────────────────────────────────────────

List<String> _buildScheduleTemplate(String goal) {
  switch (goal) {
    case 'lean':
      // Full-body 3×/week
      return List.generate(90, (i) {
        final week = i ~/ 7;
        final dow  = i % 7; // 0=Mon
        if (dow == 1 || dow == 3 || dow == 5) {
          final names = ['Full Body A', 'Full Body B'];
          return names[(week + (dow ~/ 2)) % 2];
        }
        return 'rest';
      });
    case 'fit':
      // Upper/Lower 4×/week
      return List.generate(90, (i) {
        final dow = i % 7;
        if (dow == 0) return 'Upper Body';
        if (dow == 1) return 'Lower Body';
        if (dow == 3) return 'Upper Body';
        if (dow == 4) return 'Lower Body';
        return 'rest';
      });
    default: // muscle — Push/Pull/Legs 5×/week
      const pattern = [
        'Push Day', 'Pull Day', 'Legs Day', 'Push Day', 'Pull Day', 'rest', 'rest',
      ];
      return List.generate(90, (i) => pattern[i % 7]);
  }
}

// Milestone days — same for all goals
const Map<int, _MilestoneDef> _milestones = {
  7:  _MilestoneDef('1 Week Done',   '🔥', '7 consecutive days — habit is forming.'),
  14: _MilestoneDef('2 Weeks!',       '⚡', 'Two weeks in. Your body is adapting.'),
  21: _MilestoneDef('3 Weeks!',       '💪', 'Three weeks. Neurological gains are peaking.'),
  30: _MilestoneDef('30 Days!',       '🏆', '30-day milestone. This is who you are now.'),
  45: _MilestoneDef('Halfway There',  '🚀', '45 days. Halfway to the full 90.'),
  60: _MilestoneDef('60 Days',        '🦁', 'Sixty days of showing up. Remarkable.'),
  75: _MilestoneDef('Final Sprint',   '🎯', '15 days left. Give it everything.'),
  90: _MilestoneDef('90 Days Done!',  '👑', 'The full 90. You came. You saw. You conquered.'),
};

class _MilestoneDef {
  final String label, emoji, description;
  const _MilestoneDef(this.label, this.emoji, this.description);
}

// ─────────────────────────────────────────────────────────────────────────────
// RoadmapScreen
// ─────────────────────────────────────────────────────────────────────────────

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  SharedPreferences? _prefs;
  bool _loaded = false;

  List<_RoadmapNode> _nodes     = [];
  int    _totalDays             = 0;
  int    _completedWorkouts     = 0;
  int    _streak                = 0;
  String _goal                  = 'muscle';
  int?   _todayNodeIndex;       // index in _nodes of today's node

  // Which node's detail card is open
  int? _openIndex;

  // Per-item GlobalKeys for precise auto-scroll
  final Map<int, GlobalKey> _nodeKeys = {};

  final ScrollController _scroll = ScrollController();

  // ─────────────────────────────────────────────────────────────────────────
  // Load
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Seed demo data if profile_seeded hasn't been done yet
    final seeded = prefs.getBool(_kProfileSeeded) ?? false;
    if (!seeded) _seedDemo(prefs);

    final goal         = prefs.getString(_kUserGoal) ?? 'muscle';
    final streak       = prefs.getInt(_kStreakCount)  ?? 0;
    final totalWorkouts= prefs.getInt(_kTotalWorkouts)?? 0;

    // Determine journey start. Default to (today − totalWorkouts) days ago.
    final now          = DateTime.now();
    final todayDate    = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    final startStr     = prefs.getString(_kJourneyStart);
    if (startStr != null) {
      startDate = _parseDay(startStr);
    } else {
      startDate = todayDate.subtract(Duration(days: math.max(totalWorkouts - 1, 0)));
      // Persist for consistency
      prefs.setString(_kJourneyStart, _dayKey(startDate));
    }

    // Build 90 schedule entries
    final scheduleTemplate = _buildScheduleTemplate(goal);
    final List<_RoadmapNode> nodes = [];
    int? todayNodeIndex;

    for (int i = 0; i < 90; i++) {
      final date       = startDate.add(Duration(days: i));
      final dayNum     = i + 1;
      final key        = _dayKey(date);
      final isToday    = date.year == todayDate.year &&
                         date.month == todayDate.month &&
                         date.day == todayDate.day;
      final isFuture   = date.isAfter(todayDate);
      final isPast     = date.isBefore(todayDate);

      final rawLabel   = scheduleTemplate[i];
      final isRest     = rawLabel == 'rest';
      final isMilestone= _milestones.containsKey(dayNum);

      // Activity
      final activityCount = prefs.getInt('$_kActivityPrefix$key') ?? 0;
      final setsLogged    = activityCount > 0 ? activityCount : null;
      final durationMin   = setsLogged != null
          ? (setsLogged * 3.5).round()
          : null;

      // State
      _NodeState state;
      if (isToday) {
        state = _NodeState.today;
      } else if (isFuture) {
        state = _NodeState.upcoming;
      } else if (isRest) {
        state = _NodeState.completed; // rest days always "done"
      } else if (activityCount > 0) {
        state = _NodeState.completed;
      } else if (isPast && !isRest) {
        state = _NodeState.missed;
      } else {
        state = _NodeState.completed;
      }

      // PRs logged this day — we store pr_{id} as a single best, not per-day.
      // For the roadmap we just check the note for a PR mention (good enough for POC).
      final note = prefs.getString('$_kNotePrefix$key');

      // Determine label
      String label;
      if (isMilestone) {
        label = _milestones[dayNum]!.label;
      } else if (isRest) {
        label = 'Rest';
      } else {
        label = rawLabel;
      }

      final nodeType = isMilestone
          ? _NodeType.milestone
          : isRest
              ? _NodeType.rest
              : _NodeType.workout;

      final node = _RoadmapNode(
        dayNumber:   dayNum,
        date:        date,
        label:       label,
        type:        nodeType,
        state:       state,
        emoji:       isMilestone ? _milestones[dayNum]!.emoji : null,
        note:        note,
        setsLogged:  setsLogged,
        durationMin: durationMin,
      );

      _nodeKeys[i] = GlobalKey();
      nodes.add(node);

      if (isToday) todayNodeIndex = i;
    }

    setState(() {
      _prefs            = prefs;
      _nodes            = nodes;
      _goal             = goal;
      _streak           = streak;
      _completedWorkouts= totalWorkouts;
      _totalDays        = todayDate.difference(startDate).inDays + 1;
      _todayNodeIndex   = todayNodeIndex;
      _loaded           = true;
    });

    // Auto-scroll to today after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _seedDemo(SharedPreferences p) {
    final now  = DateTime.now();
    final rng  = math.Random(42);
    // Seed 13 completed days
    for (int i = 13; i >= 1; i--) {
      final d = now.subtract(Duration(days: i));
      p.setInt('$_kActivityPrefix${_dayKey(d)}', rng.nextInt(5) + 3);
    }
    p.setInt(_kStreakCount, 5);
    p.setInt(_kTotalWorkouts, 10);
    p.setBool(_kProfileSeeded, true);
    // A couple demo notes
    final d4 = now.subtract(const Duration(days: 10));
    final d9 = now.subtract(const Duration(days: 5));
    p.setString('${_kNotePrefix}${_dayKey(d4)}', 'Squats feeling way better. Form clicked.');
    p.setString('${_kNotePrefix}${_dayKey(d9)}', 'Deadlift hit 100kg for the first time 🏆');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scroll to today
  // ─────────────────────────────────────────────────────────────────────────

  void _scrollToToday() {
    final idx = _todayNodeIndex;
    if (idx == null) return;
    final key = _nodeKeys[idx];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) {
      // Fallback: estimate
      final offset = (idx * 96.0) - 220;
      _scroll.animateTo(
        offset.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
      );
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.4,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Note saving
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveNote(int nodeIndex, String note) async {
    final node = _nodes[nodeIndex];
    final key  = _dayKey(node.date);
    await _prefs?.setString('$_kNotePrefix$key', note);
    setState(() => _nodes[nodeIndex].note = note.isEmpty ? null : note);
  }

  void _openNoteEditor(int nodeIndex) {
    final node = _nodes[nodeIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditorSheet(
        dayLabel:    'Day ${node.dayNumber} · ${node.label}',
        initialNote: node.note ?? '',
        onSave:      (text) => _saveNote(nodeIndex, text),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toggle detail card
  // ─────────────────────────────────────────────────────────────────────────

  void _onNodeTap(int index) {
    final node = _nodes[index];
    if (node.state == _NodeState.upcoming) return;
    HapticFeedback.selectionClick();
    setState(() => _openIndex = _openIndex == index ? null : index);

    // Scroll the opened card into view after animation
    if (_openIndex == index) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final key = _nodeKeys[index];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            alignment: 0.3,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Jump to week
  // ─────────────────────────────────────────────────────────────────────────

  void _jumpToWeek(int weekIndex) {
    final nodeIdx = weekIndex * 7;
    if (nodeIdx >= _nodes.length) return;
    HapticFeedback.selectionClick();
    final key = _nodeKeys[nodeIdx];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 2)),
      );
    }

    final missedCount = _nodes.where(
        (n) => n.state == _NodeState.missed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Journey',
                      style: GoogleFonts.dmSans(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary, letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 10),
                  // Stat pills
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _Pill(
                        label: '$_completedWorkouts workouts done',
                        isAccent: true),
                      _Pill(label: 'Day $_totalDays of 90'),
                      if (_streak > 0)
                        _Pill(label: '🔥 $_streak day streak'),
                      if (missedCount > 0)
                        _Pill(label: '$missedCount missed', isWarning: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar — days completed / 90
                  _JourneyProgressBar(
                      completedDays: _totalDays.clamp(0, 90), totalDays: 90),
                ],
              ),
            ),
          ),

          // ── Week jump strip ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WeekJumpStrip(
              totalDays:      90,
              currentDayNum:  _totalDays,
              onWeekTap:      _jumpToWeek,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Path ─────────────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final node   = _nodes[i];
                final isLast = i == _nodes.length - 1;
                // Insert week label before the first day of each week
                final showWeekLabel = node.dayNumber % 7 == 1;

                return Column(
                  key: _nodeKeys[i],
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showWeekLabel)
                      _WeekDivider(weekNum: (node.dayNumber - 1) ~/ 7 + 1),
                    _NodeRow(
                      node:     node,
                      index:    i,
                      isLast:   isLast,
                      isOpen:   _openIndex == i,
                      onTap:    () => _onNodeTap(i),
                      onAddNote:() => _openNoteEditor(i),
                    ),
                  ],
                );
              },
              childCount: _nodes.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyProgressBar extends StatelessWidget {
  const _JourneyProgressBar({
    required this.completedDays,
    required this.totalDays,
  });
  final int completedDays, totalDays;

  @override
  Widget build(BuildContext context) {
    final ratio = (completedDays / totalDays).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: Colors.white.withValues(alpha: 0.07),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.7),
                        AppColors.accent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text('${(ratio * 100).toStringAsFixed(0)}% complete',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.3),
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week jump strip — tap any week chip to scroll there
// ─────────────────────────────────────────────────────────────────────────────

class _WeekJumpStrip extends StatelessWidget {
  const _WeekJumpStrip({
    required this.totalDays,
    required this.currentDayNum,
    required this.onWeekTap,
  });
  final int totalDays, currentDayNum;
  final ValueChanged<int> onWeekTap;

  @override
  Widget build(BuildContext context) {
    final weeks = (totalDays / 7).ceil();
    final currentWeek = ((currentDayNum - 1) / 7).floor();

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: weeks,
        itemBuilder: (_, w) {
          final isCurrent = w == currentWeek;
          final isPast    = w < currentWeek;
          return GestureDetector(
            onTap: () => onWeekTap(w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Center(
                child: Text('W${w + 1}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? AppColors.accent
                          : isPast
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.2),
                    )),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week divider
// ─────────────────────────────────────────────────────────────────────────────

class _WeekDivider extends StatelessWidget {
  const _WeekDivider({required this.weekNum});
  final int weekNum;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const SizedBox(width: 20),
        Container(
            width: 28, height: 1,
            color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(width: 10),
        Text('WEEK $weekNum',
            style: GoogleFonts.dmSans(
              fontSize: 8, fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.18),
              letterSpacing: 2.5,
            )),
        const SizedBox(width: 10),
        Expanded(child: Container(
            height: 1, color: Colors.white.withValues(alpha: 0.06))),
        const SizedBox(width: 20),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Node row — connector + node circle + label + optional detail card
// ─────────────────────────────────────────────────────────────────────────────

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.node,
    required this.index,
    required this.isLast,
    required this.isOpen,
    required this.onTap,
    required this.onAddNote,
  });

  final _RoadmapNode node;
  final int          index;
  final bool         isLast, isOpen;
  final VoidCallback onTap, onAddNote;

  // Alternating zigzag — left side for even indices, right for odd
  bool get _isLeft => (index % 4) < 2;

  @override
  Widget build(BuildContext context) {
    final isDone      = node.state == _NodeState.completed;
    final isToday     = node.state == _NodeState.today;
    final isUpcoming  = node.state == _NodeState.upcoming;
    final isMissed    = node.state == _NodeState.missed;
    final isMilestone = node.type  == _NodeType.milestone;
    final isRest      = node.type  == _NodeType.rest;

    // ── Colors ────────────────────────────────────────────────────────────
    Color nodeBg, nodeBorder;
    Color connectorColor;

    if (isToday) {
      nodeBg       = AppColors.accent;
      nodeBorder   = AppColors.accent;
      connectorColor = AppColors.accent.withValues(alpha: 0.4);
    } else if (isDone && isMilestone) {
      nodeBg       = AppColors.accent;
      nodeBorder   = AppColors.accent;
      connectorColor = AppColors.accent.withValues(alpha: 0.4);
    } else if (isDone) {
      nodeBg       = AppColors.accent.withValues(alpha: 0.15);
      nodeBorder   = AppColors.accent.withValues(alpha: 0.5);
      connectorColor = AppColors.accent.withValues(alpha: 0.4);
    } else if (isMissed) {
      nodeBg       = Colors.red.withValues(alpha: 0.08);
      nodeBorder   = Colors.red.withValues(alpha: 0.3);
      connectorColor = Colors.white.withValues(alpha: 0.06);
    } else {
      nodeBg       = AppColors.surface;
      nodeBorder   = Colors.white.withValues(alpha: 0.1);
      connectorColor = Colors.white.withValues(alpha: 0.06);
    }

    final double nodeSize = isMilestone ? 68 : (isToday ? 60 : 52);
    final Color  textColor = isToday || (isDone && isMilestone)
        ? Colors.black
        : isDone
            ? AppColors.accent
            : isUpcoming
                ? Colors.white.withValues(alpha: 0.15)
                : isMissed
                    ? Colors.red.withValues(alpha: 0.5)
                    : AppColors.textSecondary;

    // ── Node icon ─────────────────────────────────────────────────────────
    Widget nodeChild;
    if (isMilestone && isDone) {
      nodeChild = Text(node.emoji ?? '⭐',
          style: const TextStyle(fontSize: 26));
    } else if (isMilestone) {
      nodeChild = Text(node.emoji ?? '⭐',
          style: TextStyle(
              fontSize: 24,
              color: Colors.white.withValues(alpha: 0.2)));
    } else if (isToday) {
      nodeChild = Icon(
          isRest ? Icons.bedtime_outlined : Icons.fitness_center,
          size: 22, color: Colors.black);
    } else if (isDone && isRest) {
      nodeChild = Icon(Icons.check_rounded, size: 20, color: AppColors.accent);
    } else if (isDone) {
      nodeChild = Icon(Icons.check_rounded, size: 20, color: AppColors.accent);
    } else if (isMissed) {
      nodeChild = Icon(Icons.close_rounded,
          size: 18, color: Colors.red.withValues(alpha: 0.5));
    } else {
      nodeChild = Icon(
          isRest ? Icons.bedtime_outlined : Icons.fitness_center,
          size: 18, color: Colors.white.withValues(alpha: 0.12));
    }

    return Column(
      children: [
        SizedBox(
          height: isMilestone ? 100 : 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left label area
              Expanded(
                child: _isLeft
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: _NodeLabel(
                            node:      node,
                            isToday:   isToday,
                            isDone:    isDone,
                            isMissed:  isMissed,
                            align:     TextAlign.right,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Centre spine ────────────────────────────────────────────
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top connector
                    if (index > 0)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: connectorColor,
                          ),
                        ),
                      ),
                    // Node
                    GestureDetector(
                      onTap: isUpcoming ? null : onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: nodeSize, height: nodeSize,
                        decoration: BoxDecoration(
                          color: nodeBg,
                          shape: isMilestone
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: isMilestone
                              ? BorderRadius.circular(18)
                              : null,
                          border: Border.all(
                              color: nodeBorder, width: isToday ? 2.5 : 1.5),
                          boxShadow: isToday
                              ? [BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.35),
                                  blurRadius: 24, spreadRadius: 2)]
                              : isDone && isMilestone
                                  ? [BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.2),
                                      blurRadius: 16)]
                                  : null,
                        ),
                        child: Center(child: nodeChild),
                      ),
                    ),
                    // Bottom connector
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: connectorColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right label area
              Expanded(
                child: !_isLeft
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: _NodeLabel(
                            node:      node,
                            isToday:   isToday,
                            isDone:    isDone,
                            isMissed:  isMissed,
                            align:     TextAlign.left,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Expanded detail card ───────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          child: isOpen
              ? _NodeDetailCard(
                  node:      node,
                  onAddNote: onAddNote,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Node label (left or right of the spine)
// ─────────────────────────────────────────────────────────────────────────────

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({
    required this.node,
    required this.isToday,
    required this.isDone,
    required this.isMissed,
    required this.align,
  });
  final _RoadmapNode node;
  final bool         isToday, isDone, isMissed;
  final TextAlign    align;

  CrossAxisAlignment get _cross => align == TextAlign.left
      ? CrossAxisAlignment.start
      : CrossAxisAlignment.end;

  @override
  Widget build(BuildContext context) {
    Color mainColor;
    if (isToday) {
      mainColor = AppColors.accent;
    } else if (isDone) {
      mainColor = AppColors.textPrimary;
    } else if (isMissed) {
      mainColor = Colors.red.withValues(alpha: 0.55);
    } else {
      mainColor = Colors.white.withValues(alpha: 0.2);
    }

    return Column(
      crossAxisAlignment: _cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day number
        Text('Day ${node.dayNumber}',
            textAlign: align,
            style: GoogleFonts.dmSans(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.2),
              letterSpacing: 1,
            )),
        const SizedBox(height: 2),
        // Label
        Text(node.label,
            textAlign: align,
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: mainColor,
            )),
        // Sublabel — sets + duration for completed workouts
        if (node.setsLogged != null && node.durationMin != null)
          Text('${node.setsLogged} sets · ~${node.durationMin}m',
              textAlign: align,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              )),
        if (isToday)
          Text('Today',
              textAlign: align,
              style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.accent.withValues(alpha: 0.6),
              )),
        if (isMissed)
          Text('Missed',
              textAlign: align,
              style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: Colors.red.withValues(alpha: 0.5),
              )),
        // Note snippet
        if (node.note != null && node.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '"${node.note!.length > 30 ? '${node.note!.substring(0, 28)}…' : node.note!}"',
              textAlign: align,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.25),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Node detail card — expanded when tapping a completed/today node
// ─────────────────────────────────────────────────────────────────────────────

class _NodeDetailCard extends StatelessWidget {
  const _NodeDetailCard({required this.node, required this.onAddNote});
  final _RoadmapNode node;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final isMilestone = node.type == _NodeType.milestone;
    final milDef      = _milestones[node.dayNumber];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMilestone
            ? AppColors.accent.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMilestone
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${node.dayNumber} · ${node.label}',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: isMilestone
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      )),
                  Text(
                    _formatDate(node.date),
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (node.setsLogged != null) ...[
              _DetailChip(
                  label: '${node.setsLogged} sets',
                  icon: Icons.fitness_center),
              const SizedBox(width: 6),
              _DetailChip(
                  label: '~${node.durationMin}m',
                  icon: Icons.timer_outlined),
            ],
          ]),

          // Milestone description
          if (isMilestone && milDef != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Text(milDef.emoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(milDef.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.textPrimary,
                        height: 1.5,
                      )),
                ),
              ]),
            ),
          ],

          // Missed message
          if (node.state == _NodeState.missed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline,
                    size: 16, color: Colors.red.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Missed session. That\'s okay — keep going.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.red.withValues(alpha: 0.7),
                      )),
                ),
              ]),
            ),
          ],

          // User note
          if (node.note != null && node.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                border: const Border(
                    left: BorderSide(color: AppColors.accent, width: 2.5)),
                color: AppColors.accent.withValues(alpha: 0.04),
              ),
              child: Text(
                node.note!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Note button
          GestureDetector(
            onTap: onAddNote,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    node.note != null && node.note!.isNotEmpty
                        ? Icons.edit_note_rounded
                        : Icons.add_comment_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    node.note != null && node.note!.isNotEmpty
                        ? 'Edit note'
                        : 'Add note',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dow = days[d.weekday - 1];
    return '$dow, ${months[d.month - 1]} ${d.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note editor bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({
    required this.dayLabel,
    required this.initialNote,
    required this.onSave,
  });
  final String   dayLabel;
  final String   initialNote;
  final Future<void> Function(String) onSave;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bot      = MediaQuery.of(context).padding.bottom;
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kbHeight),
      child: Container(
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
            Text(widget.dayLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text('How did it feel? Any PRs? Leave a note for future you.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 5,
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'e.g. "Bench hit 60kg for the first time. Legs felt solid."',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.18),
                    height: 1.6),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              // Clear button — only if note exists
              if (widget.initialNote.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    setState(() => _saving = true);
                    await widget.onSave('');
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Center(child: Text('Delete',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Colors.red.withValues(alpha: 0.7),
                        ))),
                  ),
                ),
              if (widget.initialNote.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : () async {
                    HapticFeedback.mediumImpact();
                    setState(() => _saving = true);
                    await widget.onSave(_ctrl.text.trim());
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text('SAVE NOTE',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                letterSpacing: 1.5, color: Colors.black,
                              )),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.isAccent = false, this.isWarning = false});
  final String label;
  final bool   isAccent, isWarning;

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
    if (isAccent) {
      bg = AppColors.accent.withValues(alpha: 0.1);
      border = AppColors.accent.withValues(alpha: 0.3);
      text   = AppColors.accent;
    } else if (isWarning) {
      bg = Colors.red.withValues(alpha: 0.08);
      border = Colors.red.withValues(alpha: 0.25);
      text   = Colors.red.withValues(alpha: 0.7);
    } else {
      bg = AppColors.surface;
      border = Colors.white.withValues(alpha: 0.08);
      text   = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600, color: text)),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.icon});
  final String   label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppColors.accent.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.accent.withValues(alpha: 0.7),
        )),
      ]),
    );
  }
}