import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';

void show(BuildContext context) {
  var simpleDialog = SimpleDialog(
    title: Text('Account'),
    children: [
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
      ),


    ],
  );

  showDialog(
      context: context,
      builder: (context) {
        return simpleDialog;
      }
  );
}