import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/stundenplanProvider.dart';
import '../providers/dateUtilities.dart';
import 'package:intl/intl.dart';

class StundenplanWidget extends StatefulWidget {
  const StundenplanWidget({super.key, required this.date, required this.weeklyMode});

  final String date;
  final bool weeklyMode;

  //late int columStart = days > 1
  //    ? 0
  //    : getWeekStartOffset(DateFormat("dd.MM.yyyy").parse(date)) + 1;

  @override
  State<StundenplanWidget> createState() => _StundenplanWidgetState();
}

class _StundenplanWidgetState extends State<StundenplanWidget> {
  bool hasColumnData(List<List<Map<String, String>>> column) {
    bool result = false;
    column.forEach((thing) {
      if(thing[0]["teacher"] != '') {
        result = true;
      };
    });
    return result;
  }

  bool isEverythingEmpty(List<List<List<Map<String, String>>>> thing) {
    for (int i = 1; i < thing.length ; i++) {
      if(hasColumnData(thing[i])) {
        return false;
      }
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    String requestPage = widget.weeklyMode
        ? 'page-5'
        : 'page2';


    return FutureBuilder<List<List<List<Map<String, String>>>>>(
        future: getWeeklyStundenplan(
            widget.date,
            page: requestPage
        ),
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

                      // This is horrible
                      if(isEverythingEmpty(stundenplan))
                        Text("Nichts :)"),
                      if(!isEverythingEmpty(stundenplan))
                        for (int i = 0; i < stundenplan.length ; i++)
                        if(hasColumnData(stundenplan[i])) // Only render column if has data
                          IntrinsicWidth(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: !widget.weeklyMode && i == 1
                                  ? (MediaQuery.sizeOf(context).width )
                                  : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if(i > 0)
                                      Text(
                                          widget.weeklyMode
                                            ? formatDate('dd.MM', getNthDayOfWeek(DateFormat("dd.MM.yyyy").parse(widget.date), i))
                                            : formatDate('dd.MM', DateFormat("dd.MM").parse(widget.date)),
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
                                                child: GestureDetector(
                                                  onTap: () {
                                                    String date = formatDate('dd.MM.yyyy', DateFormat("dd.MM").parse(widget.date));
                                                    if(widget.weeklyMode) {
                                                      date = formatDate('dd.MM.yyyy', getNthDayOfWeek(DateFormat("dd.MM.yyyy").parse(widget.date), i));
                                                    }

                                                    if(stundenplan[i][j][k]["lesson"] == "" && stundenplan[i][j][k]["room"] == "") {
                                                      return;
                                                    }

                                                    context.push(
                                                        "/details"
                                                            "?lesson=${stundenplan[i][j][k]["lesson"] ?? ''}"
                                                            "&teacher=${stundenplan[i][j][k]["teacher"] ?? ''}"
                                                            "&room=${stundenplan[i][j][k]["room"] ?? ''}"
                                                            "&date=$date"
                                                            "&hour=${j + 1}"
                                                    );
                                                  },
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
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
