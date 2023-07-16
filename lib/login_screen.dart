import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/home_screen.dart';
import 'auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      UserCredential? userCredential =
          await _authService.signIn(email, password);
      if (userCredential != null) {
        // Login successful, navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Login failed
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Login Failed'),
              content: Text('Invalid email or password.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // void _signup(BuildContext context) {
  @override
  Widget build(BuildContext context) {
    String imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/task-tracker-c89e2.appspot.com/o/backgroundImage%2FloginBG.jpg?alt=media&token=c1b8e80f-08fd-4db9-98c1-472beb903cda';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
          image:
              DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.fill),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // appBar: AppBar(
          //   elevation: 0.5,
          //   centerTitle: true,
          //   title: Text(
          //     'Task Tracker',
          //     style: TextStyle(color: Colors.black),
          //   ),
          //   backgroundColor: Colors.white,
          // ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Task Tracker",
                      style: GoogleFonts.kaushanScript(
                          fontSize: 45, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 20.0),
                    FractionallySizedBox(
                      widthFactor: 0.85,
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                              color: Color.fromARGB(255, 161, 161, 161)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    FractionallySizedBox(
                      widthFactor: 0.85,
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                              color: Color.fromARGB(255, 161, 161, 161)),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none),
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    FractionallySizedBox(
                      widthFactor: 0.85,
                      child: ElevatedButton(
                        onPressed: () => _login(context),
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupScreen()),
                          );
                        },
                        // Call _signup method when pressed
                        child: Text('Sign Up'),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
