import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'pages/home.dart';
import 'pages/authenticate.dart';
import 'providers/authenticationProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wichtig für async in main()
  bool authStatus = await checkAuthentication();
  runApp(MyApp(
    authenticationStatus: authStatus,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authenticationStatus});

  final bool authenticationStatus;

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(1, 236, 151, 31), // #ec971f
      brightness: Brightness.light
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(1, 236, 151, 31), // #ec971f
      brightness: Brightness.dark
  );

  @override
  Widget build(BuildContext context) {
    // Router hier definieren, damit wir auf authenticationStatus zugreifen können
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(title: "Stundenplan"),
        ),
        GoRoute(
          path: '/authenticate',
          builder: (context, state) => const AuthenticationPage(),
        ),
      ],
    );



    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp.router(
        routerConfig: router,
        title: "Better Stundenplan",
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
      );
    });
  }
}