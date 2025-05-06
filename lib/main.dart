import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'pages/HomePage.dart';
import 'pages/AuthenticationPage.dart';
import 'providers/authenticationProvider.dart';
import 'pages/DetailsPage.dart';

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
      seedColor: const Color.fromARGB(1, 197, 155, 49),  // #c59b31
      brightness: Brightness.light
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(1, 197, 155, 49), // #c59b31
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
        GoRoute(
          path: '/details',
          builder: (BuildContext context, GoRouterState state) {
            return DetailsPage(
                lesson: state.uri.queryParameters['lesson']!,
                teacher: state.uri.queryParameters['teacher']!,
                room: state.uri.queryParameters['room']!,
                date: state.uri.queryParameters['date']!,
                hour: state.uri.queryParameters['hour']!,
            );
          }
        )
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
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              // Set the predictive back transitions for Android.
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          brightness: Brightness.dark,
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              // Set the predictive back transitions for Android.
              TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            },
          ),
        ),
      );
    });
  }
}