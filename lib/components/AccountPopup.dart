import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';
import 'package:package_info_plus/package_info_plus.dart';

void showAccountPopup(BuildContext context) {
  var simpleDialog = SimpleDialog(
    title: Text('Better Stundenplan'),
    children: [
      Divider(),
      GestureDetector(
      onTap: () async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        if (context.mounted) {
           showAboutDialog(
          context: context,
          applicationName: packageInfo.appName,
          applicationVersion: packageInfo.version,
          applicationIcon: Image.asset("assets/icon.png"),
        );
      }
    },
  child: ListTile(
    leading: Icon(Icons.info_outlined),
    title: Text(
      "Über",
      style: TextStyle(
        fontSize: 18,
      ),
    ),
  ),
  ),
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