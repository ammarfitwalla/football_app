import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_team_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastAPI Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/create_team': (context) => CreateTeamScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final String uid = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => GoogleBottomBar(uid: uid),
          );
        }
        return null;
      },
    );
  }
}
