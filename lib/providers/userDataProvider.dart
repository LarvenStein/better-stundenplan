import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;

Future<Widget> getUserProfilePicture() async {
  try {
    var prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString("sessionId") ?? "";

    final response = await http.get(
      Uri.parse("https://virtueller-stundenplan.org/page2/page-22/"),
      headers: {
        'Cookie': 'PHPSESSID=$sessionId',
      },
    );

    if (response.statusCode == 200) {
      String? imageBase64 = getTheImage(response.body);

      if (imageBase64 != null) {
        return ClipOval(
          child: SizedBox.fromSize(
            size: Size.fromRadius(24), // Image radius
            child: Image.memory(base64Decode(imageBase64), fit: BoxFit.cover,),
          ),
        );
      } else {
        return const Icon(Icons.person);
      }
    } else {
      return const Icon(Icons.person);
    }
  } catch (e) {
    debugPrint('Error fetching profile picture: $e');
    return const Icon(Icons.person);
  }
}

String? getTheImage(String htmlString) {
  try {
    final document = htmlParser.parse(htmlString);
    dom.Element? image = document.querySelector('center img');

    if (image != null && image.attributes.isNotEmpty) {
      // Assuming the base64 image is in the 'src' attribute
      String? src = image.attributes['src'];

      // Remove data:image/jpeg;base64, prefix if present
      if (src != null) {
        src = src.replaceFirst(RegExp(r'^data:image/\w+;base64,'), '');
        return src;
      }
    }

    return null;
  } catch (e) {
    debugPrint('Error parsing image: $e');
    return null;
  }
}