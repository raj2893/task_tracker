import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_tracker/home_screen.dart';
import 'package:task_tracker/login_screen.dart';
import 'package:task_tracker/utilities/colors.dart';
import 'auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignupScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void _signup(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      UserCredential? userCredential =
          await _authService.signUp(email, password);
      if (userCredential != null) {
        // Signup successful, navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Signup failed
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Signup Failed'),
              content: Text('Error creating a new account.'),
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

  void _signUpWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser!.authentication;

          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential =
              await _firebaseAuth.signInWithCredential(credential);
          final User? user = userCredential.user;

          if (user != null) {
            // Sign-up successful, navigate to home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      // Sign-up failed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sign-up Failed'),
            content: Text('An error occurred while signing up with Google.'),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // appBar: AppBar(
          //   elevation: 0.5,
          //   title: Text(
          //     'Signup',
          //     style: TextStyle(color: Colors.black),
          //   ),
          //   backgroundColor: Colors.white,
          // ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Task Tracker",
                      style: GoogleFonts.kaushanScript(
                          fontSize: 45,
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    SizedBox(height: 40.0),
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
                        onPressed: () => _signup(context),
                        child: Text(
                          'SignUp',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            backgroundColor: Color.fromARGB(255, 179, 254, 242),
                            padding: EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(color: textColor),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        // Call _signup method when pressed
                        child: Text(
                          'Login',
                          style: TextStyle(
                              color: Color.fromARGB(255, 68, 255, 211)),
                        ),
                      ),
                    ]),
                    SizedBox(height: 25.0),
                    Text(
                      'OR',
                      style: TextStyle(color: textColor),
                    ),
                    SizedBox(height: 25.0),
                    FractionallySizedBox(
                      widthFactor: 0.85,
                      child: ElevatedButton(
                        onPressed: () => _signUpWithGoogle(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Image.asset(
                                'assets/google.png',
                                height:
                                    MediaQuery.of(context).size.height * 0.04,
                              ),
                            ),
                            Text('Sign up with Google',
                                style: TextStyle(color: Colors.black)),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
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
