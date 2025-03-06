import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';

void showAccountPopup(BuildContext context) {
  var simpleDialog = SimpleDialog(
    title: Text('Better Stundenplan'),
    children: [
      Divider(),
      GestureDetector(
        onTap: () {
          deleteAuthentication();
          context.pushReplacement("/authenticate");
        },
        child: ListTile(
          leading: Icon(Icons.logout),
          title: Text(
              "Logout",
            style: TextStyle(
              fontSize: 18,
            ),
          )
        ),
      )
  ],
  );

  showDialog(
      context: context,
      builder: (context) {
        return simpleDialog;
      }
  );
}