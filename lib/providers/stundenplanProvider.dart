import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

// ============================================================================
// Data Models
// ============================================================================

/// Represents a single lesson entry with subject, teacher, and room information
class LessonEntry {
  final String lesson;
  final String teacher;
  final String room;

  const LessonEntry({
    required this.lesson,
    required this.teacher,
    required this.room,
  });

  /// Creates an empty lesson entry
  factory LessonEntry.empty() {
    return const LessonEntry(
      lesson: ' ',
      teacher: ' ',
      room: ' ',
    );
  }

  /// Creates a lesson entry from a map
  factory LessonEntry.fromMap(Map<String, String> map) {
    return LessonEntry(
      lesson:  map['lesson'] ?? ' ',
      teacher: map['teacher'] ??  ' ',
      room: map['room'] ?? ' ',
    );
  }

  /// Converts the lesson entry to a map
  Map<String, String> toMap() {
    return {
      'lesson': lesson,
      'teacher': teacher,
      'room': room,
    };
  }

  /// Checks if the lesson entry is effectively empty
  bool get isEmpty =>
      lesson.trim().isEmpty &&
          teacher.trim().isEmpty &&
          room.trim().isEmpty;

  @override
  String toString() =>
      'LessonEntry(lesson: $lesson, teacher: $teacher, room: $room)';
}

/// Represents a time slot (period) containing one or more lesson entries
class TimeSlot {
  final int period;
  final List<LessonEntry> lessons;

  const TimeSlot({
    required this.period,
    required this.lessons,
  });

  /// Creates an hour marker time slot (for display purposes)
  factory TimeSlot.hourMarker(int hour) {
    return TimeSlot(
      period: hour,
      lessons: [
        LessonEntry(
          lesson: ' ',
          teacher: hour.toString(),
          room: ' ',
        ),
      ],
    );
  }

  /// Checks if this is an hour marker slot
  bool get isHourMarker =>
      lessons.length == 1 &&
          lessons. first.lesson.trim().isEmpty &&
          lessons.first.room.trim().isEmpty;

  @override
  String toString() => 'TimeSlot(period:  $period, lessons: $lessons)';
}

/// Represents a daily timetable
class DailyTimetable {
  final DateTime date;
  final List<TimeSlot> timeSlots;

  const DailyTimetable({
    required this.date,
    required this.timeSlots,
  });

  /// Creates an empty daily timetable
  factory DailyTimetable.empty(DateTime date) {
    return DailyTimetable(date: date, timeSlots: []);
  }

  bool get isEmpty => timeSlots.isEmpty;

  @override
  String toString() =>
      'DailyTimetable(date: $date, slots: ${timeSlots.length})';
}

/// Represents a weekly timetable
class WeeklyTimetable {
  final DateTime weekStart;
  final List<TimeSlot> hourMarkers;
  final List<DailyTimetable> days;

  const WeeklyTimetable({
    required this. weekStart,
    required this. hourMarkers,
    required this.days,
  });

  @override
  String toString() =>
      'WeeklyTimetable(weekStart: $weekStart, days: ${days.length})';
}

// ============================================================================
// Service Class
// ============================================================================

/// Service for fetching and parsing timetable data
class StundenplanService {
  static const String _baseUrl =
      'https://virtueller-stundenplan.org/page2/index.php';
  static const String _sessionIdKey = 'sessionId';

  /// Gets the Monday of the week containing the given date
  static DateTime getMondayOfWeek(String dateString) {
    final parsedDate = DateFormat('dd.MM.yyyy').parse(dateString);
    final daysFromMonday = parsedDate.weekday - 1;
    return parsedDate.subtract(Duration(days: daysFromMonday));
  }

  /// Fetches the weekly timetable starting from the given date
  static Future<WeeklyTimetable> getWeeklyTimetable(
      String date, {
        String page = 'page-5',
      }) async {
    // Handle single day view
    if (page != 'page-5') {
      final dailyTimetable = await getDailyTimetable(date);
      final hourMarkers = _generateHourMarkers(dailyTimetable. timeSlots);

      return WeeklyTimetable(
        weekStart: dailyTimetable.date,
        hourMarkers: hourMarkers,
        days: [dailyTimetable],
      );
    }

    // Handle weekly view
    final weekStart = getMondayOfWeek(date);
    final List<DailyTimetable> weekDays = [];
    List<TimeSlot> hourMarkers = [];

    for (int i = 0; i < 7; i++) {
      final currentDay = weekStart.add(Duration(days: i));
      final formattedDate = DateFormat('dd.MM.yyyy').format(currentDay);
      final dailyTimetable = await getDailyTimetable(formattedDate);

      // Generate hour markers from first day
      if (i == 0) {
        hourMarkers = _generateHourMarkers(dailyTimetable.timeSlots);
      }

      weekDays.add(dailyTimetable);
    }

    return WeeklyTimetable(
      weekStart: weekStart,
      hourMarkers: hourMarkers,
      days: weekDays,
    );
  }

  /// Fetches the daily timetable for the given date
  static Future<DailyTimetable> getDailyTimetable(String dateString) async {
    final date = DateFormat('dd.MM.yyyy').parse(dateString);

    try {
      final sessionId = await _getSessionId();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?KlaBuDatum=$dateString&HideChangesOff=1&CompactOff=1',
        ),
        headers: {
          'Cookie': 'PHPSESSID=$sessionId',
        },
      );

      if (response.statusCode == 200) {
        final timeSlots = _parseHtmlResponse(response.body);
        return DailyTimetable(date: date, timeSlots: timeSlots);
      } else {
        return DailyTimetable. empty(date);
      }
    } catch (e) {
      return DailyTimetable.empty(date);
    }
  }

  /// Retrieves the session ID from shared preferences
  static Future<String> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionIdKey) ?? '';
  }

  /// Generates hour marker time slots for display
  static List<TimeSlot> _generateHourMarkers(List<TimeSlot> referenceSlots) {
    final hourMarkers = <TimeSlot>[];

    for (int i = 0; i < referenceSlots.length; i++) {
      hourMarkers.add(TimeSlot.hourMarker(i + 1));
    }

    return hourMarkers;
  }

  /// Parses the HTML response into time slots
  static List<TimeSlot> _parseHtmlResponse(String htmlString) {
    final timeSlots = <TimeSlot>[];

    try {
      final document = html_parser.parse(htmlString);

      final teacherTable =
      document.querySelector('div[data-title=LK] #editableTable');
      final lessonTable =
      document.querySelector('div[data-title=Fach] #editableTable');
      final roomTable =
      document.querySelector('div[data-title=Raum] #editableTable');

      // Return empty if no tables found
      if (teacherTable == null && lessonTable == null && roomTable == null) {
        return timeSlots;
      }

      // Extract data from each table
      final teachers = _extractTableColumnData(teacherTable);
      final lessons = _extractTableColumnData(lessonTable);
      final rooms = _extractTableColumnData(roomTable);

      // Get maximum number of rows
      final maxRows = [teachers. length, lessons.length, rooms. length]
          .reduce((a, b) => a > b ? a : b);

      if (maxRows == 0) {
        return timeSlots;
      }

      // Combine data from all three tables row by row
      for (int i = 0; i < maxRows; i++) {
        final rowTeachers = i < teachers.length ? teachers[i] : [''];
        final rowLessons = i < lessons.length ? lessons[i] : [''];
        final rowRooms = i < rooms.length ? rooms[i] : [''];

        final lessonEntries = _combineLessonData(
          rowTeachers,
          rowLessons,
          rowRooms,
        );

        // Only add non-empty time slots
        if (lessonEntries.isNotEmpty) {
          timeSlots. add(TimeSlot(
            period: i + 1,
            lessons: lessonEntries,
          ));
        }
      }
    } catch (e) {
      // Return empty list on error
    }

    return timeSlots;
  }

  /// Extracts column data from a table element
  static List<List<String>> _extractTableColumnData(dom.Element?  table) {
    final columnData = <List<String>>[];

    if (table == null) return columnData;

    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return columnData;

    // Skip the header row (index 0)
    for (int i = 1; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll('td');

      // Get the second column (index 1) if it exists
      if (cells. length > 1) {
        final cellValues = _extractCellValues(cells[1]);
        columnData.add(cellValues. isEmpty ? [''] : cellValues);
      }
    }

    return columnData;
  }

  /// Extracts text values from a table cell
  static List<String> _extractCellValues(dom. Element cell) {
    final cellValues = <String>[];

    // Check for bold elements (new/updated values)
    final boldElements = cell.querySelectorAll('b');

    if (boldElements.isNotEmpty) {
      // Extract only bold text
      for (final bold in boldElements) {
        final cellText = _normalizeText(bold.text.trim() ?? '');
        if (cellText. isNotEmpty) {
          cellValues.add(cellText);
        }
      }
    } else {
      // No bold elements, process all text nodes
      final brTags = cell.querySelectorAll('br');

      if (brTags.isNotEmpty) {
        // Multiple entries separated by <br>
        final innerHTML = cell.innerHtml;
        final parts = innerHTML.split('<br>');

        for (final part in parts) {
          final cleanText = _normalizeText(
            part.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          );
          if (cleanText.isNotEmpty) {
            cellValues. add(cleanText);
          }
        }
      } else {
        // Single entry
        for (final node in cell.nodes) {
          final cellText = _normalizeText(node.text?.trim() ?? '');
          if (cellText.isNotEmpty) {
            cellValues.add(cellText);
          }
        }
      }
    }

    return cellValues;
  }

  /// Normalizes text by replacing dashes and cleaning room numbers
  static String _normalizeText(String text) {
    if (text == '-') return ' ';
    return text.replaceAll('+ ', '');
  }

  /// Combines teacher, lesson, and room data into lesson entries
  static List<LessonEntry> _combineLessonData(
      List<String> teachers,
      List<String> lessons,
      List<String> rooms,
      ) {
    final lessonEntries = <LessonEntry>[];

    final maxEntries = [teachers.length, lessons.length, rooms.length]
        .reduce((a, b) => a > b ? a : b);

    if (maxEntries == 0) return lessonEntries;

    for (int j = 0; j < maxEntries; j++) {
      final lesson = j < lessons.length ? lessons[j] : '';
      final teacher = j < teachers.length ? teachers[j] : '';
      final room = j < rooms.length ? rooms[j] : '';

      final entry = LessonEntry(
        lesson: lesson. isEmpty ? ' ' : lesson,
        teacher: teacher.isEmpty ? ' ' : teacher,
        room: room.isEmpty ? ' ' : room,
      );

      // Only add non-empty entries
      if (! entry.isEmpty) {
        lessonEntries.add(entry);
      }
    }

    return lessonEntries;
  }
}

