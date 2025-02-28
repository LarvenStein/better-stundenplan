import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({
    super.key,
    required this.lesson,
    required this.teacher,
    required this.room,
    required this.date,
    required this.hour
  });

  final String lesson;
  final String teacher;
  final String room;
  final String date;
  final String hour;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late final Map<String, bool> isEditing;
  late final Map<String, String> fieldKeys;
  late final Map<String, TextEditingController> controllers;
  late final Map<String, IconData> fieldIcons;
  late final Map<String, String> fieldLabels;

  @override
  void initState() {
    super.initState();

    isEditing = {
      'fach': false,
      'lehrer': false,
      'raum': false
    };

    fieldKeys = {
      'fach': widget.lesson,
      'lehrer': widget.teacher,
      'raum': widget.room
    };

    controllers = {
      'fach': TextEditingController(text: widget.lesson),
      'lehrer': TextEditingController(text: widget.teacher),
      'raum': TextEditingController(text: widget.room)
    };

    fieldIcons = {
      'fach': Icons.book,
      'lehrer': Icons.person,
      'raum': Icons.meeting_room
    };

    fieldLabels = {
      'fach': "Fach",
      'lehrer': "Lehrkraft",
      'raum': "Raum"
    };

    _loadEditedNames();
  }

  Future<void> _loadEditedNames() async {
    try {
      // Alle bearbeiteten Namen parallel laden
      final Map<String, String> editedNames = {};
      for (final key in fieldKeys.keys) {
        final editedName = await getEditedName(fieldKeys[key]!);
        editedNames[key] = editedName;
      }

      // setState nur aufrufen, wenn das Widget noch gemounted ist
      if (mounted) {
        setState(() {
          // Controller mit den geladenen Namen aktualisieren
          for (final key in editedNames.keys) {
            controllers[key]!.text = editedNames[key]!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        });
      }
      // Fehlerbehandlung hier hinzufügen
    }
  }


  Future<String> getEditedName(String key) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? key;
  }

  void toggleEdit(String field) async {
    if(isEditing[field] == true) {
      var prefs = await SharedPreferences.getInstance();

      prefs.setString(fieldKeys[field]!, controllers[field]!.value.text);
    }
    setState(() {
      isEditing[field] = !isEditing[field]!;
    });
  }


  @override
  void dispose() {
    // Controller aufräumen
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Details"),
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Column(
              children: fieldLabels.keys.map((field) => buildFieldRow(field))
                  .toList(),
            ),
            Text("${widget.hour}. Stunde - ${widget.date}")
          ],
        ),
      ),
    );
  }

  Widget buildFieldRow(String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(fieldIcons[field], size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldLabels[field]!,
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: isEditing[field],
                        controller: controllers[field],
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(width: 1),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(width: 2),
                          ),
                          disabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(width: 1),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isEditing[field]! ? Icons.save : Icons.edit,
                        size: 20,
                      ),
                      onPressed: () => toggleEdit(field),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}