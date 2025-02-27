import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../components/StundenplanWidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  // Controller für die PageView
  late PageController _pageController;

  // Aktueller Page-Index für den PageView
  int _currentPageIndex = 1000; // Starte in der Mitte eines großen Bereichs

  // Speichern des Basisdatums als State-Variable
  late DateTime _baseDate;

  // Map zum Cachen der StundenplanWidgets anhand des Datums (für Leistungsoptimierung)
  final Map<String, Widget> _cachedWidgets = {};

  @override
  void initState() {
    super.initState();
    _baseDate = DateTime.now();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Berechnet das Datum für einen bestimmten Page-Index
  DateTime _getDateForIndex(int index) {
    // Berechne die Anzahl der Wochen relativ zum Basisdatum
    int weeksDifference = index - 1000;
    return _baseDate.add(Duration(days: weeksDifference * 7));
  }

  // Formatiert ein Datum als String
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  void deleteAuth() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString("sessionId", "");
    prefs.setString("email", "");
    prefs.setString("password", "");
  }

  void chooseDate(BuildContext context) async {
    DateTime currentDate = _getDateForIndex(_currentPageIndex);

    DateTime? date = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(currentDate.year - 1, currentDate.month, currentDate.day),
      lastDate: DateTime(currentDate.year + 1, currentDate.month, currentDate.day),
    );

    // Wenn ein Datum ausgewählt wurde, berechne neuen Index und aktualisiere
    if (date != null) {
      // Berechne die Differenz in Tagen zum Basisdatum
      int dayDifference = date.difference(_baseDate).inDays;
      // Teile durch 7 und runde, um die Wochendifferenz zu erhalten
      int weekDifference = (dayDifference / 7).round();

      // Neuer Index basierend auf der Wochendifferenz
      int newIndex = 1000 + weekDifference;

      setState(() {
        _pageController.jumpToPage(newIndex);
      });
    }
  }

  void checkAuth() async {
    bool authStatus = await checkAuthentication();

    if(!authStatus) {
      context.pushReplacement('/authenticate');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAuth();

    // Aktuelles Datum für den angezeigten Index
    DateTime currentDate = _getDateForIndex(_currentPageIndex);
    String formattedDate = _formatDate(currentDate);

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.onInverseSurface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
                tooltip: 'Delete auth',
                icon: const Icon(Icons.logout),
                onPressed: deleteAuth
            ),
            Expanded(
              child: Text(
                'Datum: $formattedDate',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
                tooltip: 'Datum auswählen',
                icon: const Icon(Icons.calendar_today),
              onPressed: () => chooseDate(context),
            )
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        title: Text(widget.title),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        // Quasi unendlicher Bereich von Pages
        itemCount: 2000,
        itemBuilder: (context, index) {
          // Datum für diesen Index berechnen
          DateTime date = _getDateForIndex(index);
          String formattedDate = _formatDate(date);

          // Überprüfen, ob ein Widget für dieses Datum bereits im Cache ist
          if (!_cachedWidgets.containsKey(formattedDate)) {
            _cachedWidgets[formattedDate] = StundenplanWidget(date: formattedDate);
          }

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Verwenden des gecachten Widgets
                _cachedWidgets[formattedDate]!,
              ],
            ),
          );
        },
      ),
    );
  }
}