import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/stundenplanProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});


  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {

  void deleteAuth() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString("sessionId", "");
    prefs.setString("email", "");
    prefs.setString("password", "");
  }

  List<String> splitStunde(String stunde) {
    // Remove parentheses and commas, then trim whitespace
    String cleaned = stunde.replaceAll(RegExp(r"[(),]"), "").trim();

    // Split by any whitespace (to handle multiple spaces)
    List<String> parts = cleaned.split(RegExp(r"\s+"));

    return parts;
  }


  void checkAuth() async {
    bool authStatus = await checkAuthentication();

    if(!authStatus) {
      //context.push('/authenticate');
      context.pushReplacement('/authenticate');
      return;
    }
  }

  bool hasColumnData(List<List<Map<String, String>>> column) {
    bool result = false;
    column.forEach((thing) {
      if(thing[0]["lesson"] != '') {
        result = true;
      };
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    checkAuth();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                  onPressed: deleteAuth,
                  child: Text("Delete Auth")
              ),

          FutureBuilder<List<List<List<Map<String, String>>>>>(
              future: getWeeklyStundenplan(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final stundenplan = snapshot.data!;

                  return LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      //scrollDirection: Axis.horizontal, //This should fix the overflow issues.
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Create the column
                          for (int i = 0; i < stundenplan.length; i++)
                            if(hasColumnData(stundenplan[i])) // Only render column if has data
                              IntrinsicWidth(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (int j = 0; j < stundenplan[i].length; j++)
                                    // Render the columns for A/B lessons in this column
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                            for (int k = 0; k < stundenplan[i][j].length; k++)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      color: stundenplan[i][j][k]["lesson"] != ''
                                                          ? Theme.of(context).colorScheme.primaryContainer
                                                          : Theme.of(context).colorScheme.surfaceDim,

                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: Text(
                                                          "${stundenplan[i][j][k]["lesson"] ?? ''}\n${stundenplan[i][j][k]["teacher"] ?? ''}\n${stundenplan[i][j][k]["room"] ?? ''}",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                          ],
                                        ),
                                  ],
                                ),
                              )


                        ],
                      ),
                    );
                  });
                } else {
                  return const Center(child: Text("No data found"));
                }
              }),


          ],
          ),
        )

    );
  }
}
