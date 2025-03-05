import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> checkAuthentication() async {
    var prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString("sessionId") ?? "";

    final request = http.Request(
        "GET",
        Uri.parse("https://virtueller-stundenplan.org/page2/index.php?KlaBuDatum=19.02.2025&RES=")
    );
    request.followRedirects = false;
    request.headers['Cookie'] = 'PHPSESSID=$sessionId';
    final response = await http.Client().send(request);

    if(response.isRedirect) {
        return false;
    }

    return true;
}

Future<String?> authenticateSession(String email, String password) async {
    final request = http.Request(
        "POST",
        Uri.parse("https://virtueller-stundenplan.org/index.php")
    );
    request.followRedirects = true;

    // URL encode the body values
    final encodedBody = {
        'MAIL': Uri.encodeComponent(email),
        'SCHUELERCODE': Uri.encodeComponent(password),
        'formAction': 'login',
        'formName': 'stacks_in_368_page1'
    };

    request.body = encodedBody.entries.map((e) => '${e.key}=${e.value}').join('&');

    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';

    final response = await http.Client().send(request);

    if(response.headers.containsValue("https://virtueller-stundenplan.org:443/")) {
        return null;
    }

    // Extract session ID from Set-Cookie header
    String? sessionId;
    String? setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
        final cookies = setCookieHeader.split(',');
        for (String cookie in cookies) {
            if (cookie.trim().startsWith('PHPSESSID=')) {
                sessionId = cookie.split(';')[0].split('=')[1];
                break;
            }
        }
    }

    return sessionId;
}

Future<void> deleteAuthentication() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString("sessionId", "");
    prefs.setString("email", "");
    prefs.setString("passowrd", "");

}