import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
   LoginPage({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email validation for institutional emails
  String? _emailValidator(String? email) {
    final RegExp emailRegex = RegExp(
      r'^[a-z]+\.[a-z]{1}\.\d{4}\.[a-z0-9]+@ritchennai\.edu\.in$',
    );
    if (email == null || email.isEmpty) {
      return 'Email is required';
    } else if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid institutional email';
    }
    return null;
  }

  // Login logic
  Future<String?> _authUser(LoginData data) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: data.name.trim(),
        password: data.password,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('savedEmail', data.name);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Signup logic
  Future<String?> _signupUser(SignupData data) async {
    try {
      if (data.name == null || data.password == null) {
        return 'Missing email or password';
      }

      await _auth.createUserWithEmailAndPassword(
        email: data.name!.trim(),
        password: data.password!,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Password recovery logic
  Future<String?> _recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        title: 'Xerox Shop Arcade',
        logo: const AssetImage('assets/ritlogo.jpg'),
        onLogin: _authUser,
        onSignup: _signupUser,
        onRecoverPassword: _recoverPassword,
        userValidator: _emailValidator,
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacementNamed('/home');
        },
        messages:  LoginMessages(
          userHint: 'Email',
          passwordHint: 'Password',
          confirmPasswordHint: 'Confirm',
          loginButton: 'LOGIN',
          signupButton: 'REGISTER',
          forgotPasswordButton: 'Forgot Password?',
          recoverPasswordButton: 'HELP',
          goBackButton: 'BACK',
          confirmPasswordError: 'Passwords do not match!',
          recoverPasswordIntro: 'We will send a recovery email.',
          recoverPasswordDescription: 'Enter your institutional email.',
          recoverPasswordSuccess: 'Check your inbox.Also check in your Spam box',
        ),
        theme: LoginTheme(
          primaryColor: Color(0xFF6EACDA),
          cardTheme: CardTheme(
            color: Color(0xFF021526),         // Color of login card
            elevation: 5,
            margin: EdgeInsets.only(top: 15),
          ),
          titleStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
