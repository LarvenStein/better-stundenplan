import 'package:flutter/material.dart';
import '../providers/stundenplanProvider.dart';
import '../providers/dateUtilities.dart';
import 'package:intl/intl.dart';

class StundenplanWidget extends StatefulWidget {
  const StundenplanWidget({super.key, required this.date});

  final String date;

  @override
  State<StundenplanWidget> createState() => _StundenplanWidgetState();
}

class _StundenplanWidgetState extends State<StundenplanWidget> {
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
    return FutureBuilder<List<List<List<Map<String, String>>>>>(
        future: getWeeklyStundenplan(widget.date),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Create the column
                      for (int i = 0; i < stundenplan.length; i++)
                        if(hasColumnData(stundenplan[i])) // Only render column if has data
                          IntrinsicWidth(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if(i > 0)
                                    Text(
                                        formatDate('dd.MM', getNthDayOfWeek(DateFormat("dd.MM.yyyy").parse(widget.date), i)),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10
                                        ),
                                    ),
                                  for (int j = 0; j < stundenplan[i].length; j++)
                                  // Render the columns for A/B lessons in this column
                                  IntrinsicHeight(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          for (int k = 0; k < stundenplan[i][j].length; k++)
                                            Expanded(
                                              child: Container(
                                                margin: stundenplan[i][j].length > 1 && k < stundenplan[i][j].length -1
                                                  ? EdgeInsets.only(right: 5)
                                                  : EdgeInsets.zero,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                                  color: stundenplan[i][j][k]["lesson"] != '' && i != 0
                                                      ? Theme.of(context).colorScheme.primaryContainer
                                                      : Theme.of(context).colorScheme.surfaceDim,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    "${stundenplan[i][j][k]["lesson"] ?? ''}\n"
                                                        "${stundenplan[i][j][k]["teacher"] ?? ''}\n"
                                                        "${stundenplan[i][j][k]["room"] ?? ''}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )


                    ],
                  ),
                ),
              );
            });
          } else {
            return const Center(child: Text("No data found"));
          }
        });
  }
}
