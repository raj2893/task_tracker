import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_tracker/auth_service.dart';
import 'package:task_tracker/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_tracker/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // User not logged in, navigate to login screen
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Task Tracker',
              theme: ThemeData(
                  // Theme data...
                  ),
              home: LoginScreen(),
            );
          } else {
            // User logged in, navigate to home screen
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Task Tracker',
              theme: ThemeData(
                  // Theme data...
                  ),
              home: HomeScreen(),
            );
          }
        } else {
          // Loading state
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Task Tracker',
            theme: ThemeData(
                // Theme data...
                ),
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}
