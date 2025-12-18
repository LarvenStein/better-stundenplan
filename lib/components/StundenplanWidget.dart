import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/stundenplanProvider.dart';

class StundenplanWidget extends StatefulWidget {
  const StundenplanWidget({
    super.key,
    required this. date,
    required this.weeklyMode,
  });

  final String date;
  final bool weeklyMode;

  @override
  State<StundenplanWidget> createState() => _StundenplanWidgetState();
}

class _StundenplanWidgetState extends State<StundenplanWidget> {
  /// Checks if a daily timetable has any actual lesson data
  bool _hasDayData(DailyTimetable day) {
    return day.timeSlots.any((slot) =>
        slot.lessons.any((lesson) => !lesson.isEmpty)
    );
  }

  /// Checks if the entire timetable is empty
  bool _isWeekEmpty(WeeklyTimetable timetable) {
    return !timetable.days.any(_hasDayData);
  }

  /// Formats the date for display
  String _formatDateHeader(DateTime date) {
    return DateFormat('dd.MM').format(date);
  }

  /// Gets the date for a specific day in weekly mode
  DateTime _getDayDate(int dayIndex) {
    if (! widget.weeklyMode) {
      return DateFormat('dd.MM. yyyy').parse(widget.date);
    }

    // In weekly mode, get the Monday and add days
    final monday = StundenplanService.getMondayOfWeek(widget. date);
    return monday.add(Duration(days: dayIndex - 1));
  }

  /// Navigates to lesson details
  void _navigateToDetails({
    required LessonEntry lesson,
    required DateTime date,
    required int period,
  }) {
    // Don't navigate if lesson is empty
    if (lesson. lesson.trim().isEmpty && lesson.room.trim().isEmpty) {
      return;
    }

    final formattedDate = DateFormat('dd.MM.yyyy').format(date);

    context.push(
      '/details'
          '?lesson=${Uri.encodeComponent(lesson.lesson. trim())}'
          '&teacher=${Uri.encodeComponent(lesson.teacher.trim())}'
          '&room=${Uri.encodeComponent(lesson.room.trim())}'
          '&date=$formattedDate'
          '&hour=$period',
    );
  }

  /// Builds a lesson card
  Widget _buildLessonCard({
    required LessonEntry lesson,
    required bool isHourMarker,
    required bool hasMultipleLessons,
    required bool isLastLesson,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: hasMultipleLessons && ! isLastLesson
              ? const EdgeInsets.only(right: 5)
              : EdgeInsets.zero,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: ! lesson.isEmpty && !isHourMarker
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceDim,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${lesson.lesson.trim()}\n'
                  '${lesson.teacher.trim()}\n'
                  '${lesson.room. trim()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a time slot row
  Widget _buildTimeSlotRow({
    required TimeSlot slot,
    required DateTime dayDate,
    required bool isHourMarker,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child:  Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int k = 0; k < slot. lessons.length; k++)
              _buildLessonCard(
                lesson: slot.lessons[k],
                isHourMarker:  isHourMarker,
                hasMultipleLessons: slot.lessons.length > 1,
                isLastLesson: k == slot.lessons.length - 1,
                onTap:  () => _navigateToDetails(
                  lesson: slot.lessons[k],
                  date:  dayDate,
                  period:  slot.period,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a day column
  Widget _buildDayColumn({
    required List<TimeSlot> timeSlots,
    required DateTime?  date,
    required bool isHourMarker,
    required int columnIndex,
  }) {
    return IntrinsicWidth(
      child:  Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: ! widget.weeklyMode && columnIndex == 1
              ? MediaQuery.sizeOf(context).width
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date header (only for non-hour-marker columns)
              if (date != null)
                Text(
                  _formatDateHeader(date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              // Time slots
              for (final slot in timeSlots)
                _buildTimeSlotRow(
                  slot: slot,
                  dayDate: date ??  DateTime.now(),
                  isHourMarker: isHourMarker,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the timetable content
  Widget _buildTimetableContent(WeeklyTimetable timetable) {
    if (_isWeekEmpty(timetable)) {
      return const Center(
        child: Text('Nichts :  )'),
      );
    }

    final displayColumns = <Widget>[];

    // Add hour markers column
    if (timetable.hourMarkers.isNotEmpty) {
      displayColumns.add(
        _buildDayColumn(
          timeSlots: timetable.hourMarkers,
          date: null,
          isHourMarker: true,
          columnIndex: 0,
        ),
      );
    }

    // Add day columns (only non-empty days)
    for (int i = 0; i < timetable.days.length; i++) {
      final day = timetable.days[i];

      if (_hasDayData(day) || !widget.weeklyMode) {
        displayColumns.add(
          _buildDayColumn(
            timeSlots: day.timeSlots,
            date: day. date,
            isHourMarker: false,
            columnIndex: i + 1,
          ),
        );
      }
    }

    return SingleChildScrollView(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: displayColumns,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget. weeklyMode ?  'page-5' : 'page2';

    return FutureBuilder<WeeklyTimetable>(
      future: StundenplanService.getWeeklyTimetable(
        widget.date,
        page: page,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (! snapshot.hasData) {
          return const Center(
            child: Text('No data found'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return _buildTimetableContent(snapshot.data!);
          },
        );
      },
    );
  }
}