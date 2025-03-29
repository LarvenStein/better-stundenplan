import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;

Future<List<List<List<Map<String, String>>>>> getWeeklyStundenplan(String date, {String page = 'page-5'}) async {
  var prefs = await SharedPreferences.getInstance();
  String sessionId = prefs.getString("sessionId") ?? "";

  try {
    final response = await http.get(
      Uri.parse("https://virtueller-stundenplan.org/$page/index.php?KlaBuDatum=$date"),
      headers: {
        'Cookie': 'PHPSESSID=$sessionId',
      },
    );

    if (response.statusCode == 200) {
      return parseStundenplan(response.body);
    } else {
      return []; // Return an empty list in case of error
    }
  } catch (e) {
    return []; // Return an empty list in case of error
  }
}

List<List<List<Map<String, String>>>> parseStundenplan(String htmlString) {
  List<List<List<Map<String, String>>>> stundenplanData = [];

  try {
    final document = htmlParser.parse(htmlString);
    dom.Element? table = document.querySelector('#editableTable');

    if (table != null) {
      List<dom.Element> rows = table.querySelectorAll('tr');
      if (rows.isNotEmpty) {
        // Determine the number of columns based on the first row
        List<dom.Element> headerCells = rows[0].querySelectorAll('th, td'); // Use th or td
        int numCols = headerCells.length;
        if (numCols == 0) {
          return stundenplanData; // Return empty list if no columns
        }

        //Initialize the stundenplanData with empty lists for each column
        for (int i = 0; i < numCols; i++) {
          stundenplanData.add([]);
        }

        // Process each row
        for (int i = 0; i < rows.length; i++) {
          List<dom.Element> cells = rows[i].querySelectorAll('td');

          // Process each cell in the row
          for (int j = 0; j < cells.length; j++) {
            List<Map<String, String>> cellData = [];

            for(dom.Node thing in cells[j].nodes) {
              String cellText = thing.text!;

              if(cellText  == '-') {
                cellText = ' ';
              }

              if(cellText  == '') {
                continue;
              }

              cellData.add(parseLessonData(cellText));
            }

            stundenplanData[j].add(cellData); // Append to the column instead of row
          }
        }
      }
    } else {
    }
  } catch (e){}
  return stundenplanData;
}

Map<String, String> parseLessonData(String lessonText) {
  Map<String, String> lessonData = {
    'lesson': '',
    'teacher': '',
    'room': '',
  };

  // Refined parsing logic
  lessonText = lessonText.replaceAll(RegExp(r'^[AB]:'), '').trim();

  List<String> parts = lessonText.split(RegExp(r'[(),]+')); // Split on commas and parentheses
  if (parts.isNotEmpty) {
    lessonData['teacher'] = parts[0].trim(); // Lesson is the first part

    if (parts.length > 1) {
      lessonData['lesson'] = parts[1].trim(); // Teacher is the second part
    }

    if (parts.length > 2) {
      lessonData['room'] = parts[2].trim(); // Room is the third part
    }
  }

  return lessonData;
}