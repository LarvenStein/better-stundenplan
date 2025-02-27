import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/authenticationProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void trySavedCredentials(BuildContext context) async {
    var prefs = await SharedPreferences.getInstance();
    String password = prefs.getString("password") ?? "";
    String email = prefs.getString("email") ?? "";
    print(email);
    print(password);

    var sessionId = await authenticateSession(email, password);
    print(sessionId);
    if(sessionId != null) {
      prefs.setString("sessionId", sessionId);
      context.pushReplacement('/');
      return;

    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    trySavedCredentials(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Autorisierung"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Beachte, dass die Zugangsdaten UNVERSCHLÜSSELT gespeichert werden!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: (50 * 1/3),
            ),
            SizedBox(
              width: screenWidth - (50 * 2/3),
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'E-Mail',
                          border:  const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie eine E-Mail-Adresse ein';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(
                        height: (50 * 1/3),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          border:  const OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte geben Sie ein Passwort ein';
                          }
                          return null;
                        },
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(
                        height: (50 * 1/3),
                      ),
                      SizedBox(
                        width: screenWidth - (50 * 2/3),
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                            elevation: 0,
                            padding: const EdgeInsets.all(0),
                          ),

                          child: Text('Autorisieren'),
                        ),

                      ),
                    ],
                  )
              ),
            )
          ],
        ),
      ),
    );
  }

  void _submitForm() async {

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
    var sessionId = await authenticateSession(_email, _password);
    if(sessionId != null) {
      var prefs = await SharedPreferences.getInstance();
      prefs.setString("sessionId", sessionId);
      prefs.setString("email", _email);
      prefs.setString("password", _password);
      context.pushReplacement('/');
      
    }
  }

}
