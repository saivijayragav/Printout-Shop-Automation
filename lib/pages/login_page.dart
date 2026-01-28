import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Duration get loginTime => const Duration(milliseconds: 1000);

  Future<String?> _authUser(LoginData data) async {
    // We repurpose:
    // data.name -> User Name
    // data.password -> Phone Number

    // Validate Phone Number manually since FlutterLogin thinks it's a password
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(data.password)) {
      return 'Please enter a valid 10-digit phone number';
    }

    // Save Logic
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', data.name);
    await prefs.setString('userPhone', data.password);

    return null; // Return null means success
  }

  Future<String?> _recoverPassword(String name) async {
    // Not supported in simple mode
    return 'Feature not available in this mode.';
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Xerox Shop Arcade',
      logo: const AssetImage('assets/ritlogo.jpg'),
      onLogin: _authUser,
      onSignup: (data) async =>
          null, // Disable/Hide signup if possible or just map to login
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacementNamed('/home');
      },
      onRecoverPassword: _recoverPassword,

      // We customize hints to pretend it's Name/Phone
      messages: LoginMessages(
        userHint: 'Name',
        passwordHint: 'Phone Number',
        loginButton: 'CONTINUE',
        signupButton: '', // Hides signup button usually
        forgotPasswordButton: '', // Hides forgot password usually
      ),
      theme: LoginTheme(
        primaryColor: const Color(0xFF6EACDA),
        accentColor: Colors.white,
        errorColor: Colors.red,
        titleStyle: const TextStyle(
          color: Color(0xFF6EACDA),
          fontFamily: 'Quicksand',
          letterSpacing: 4,
        ),
        bodyStyle: const TextStyle(
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
        ),
        textFieldStyle: const TextStyle(
          color: Colors.white,
          shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
        ),
        buttonStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black, // Dark text on light button
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF021526),
          elevation: 5,
          margin: const EdgeInsets.only(top: 15),
          shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(100.0)),
        ),
        inputTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          contentPadding: EdgeInsets.zero,
          errorStyle: const TextStyle(
            backgroundColor: Colors.red,
            color: Colors.white,
          ),
          labelStyle: const TextStyle(fontSize: 12),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade700, width: 4),
            borderRadius: BorderRadius.circular(10), // inputBorderRadius
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade400, width: 5),
            borderRadius: BorderRadius.circular(10), // inputBorderRadius
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade700, width: 4),
            borderRadius: BorderRadius.circular(10), // inputBorderRadius
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade400, width: 5),
            borderRadius: BorderRadius.circular(10), // inputBorderRadius
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 5),
            borderRadius: BorderRadius.circular(10), // inputBorderRadius
          ),
        ),
        buttonTheme: LoginButtonTheme(
          splashColor: Colors.purple,
          backgroundColor: const Color(0xFF6EACDA),
          highlightColor: Colors.lightGreen,
          elevation: 9.0,
          highlightElevation: 6.0,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      userValidator: (value) {
        if (value == null || value.isEmpty) {
          return "Name is required";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.isEmpty) {
          return "Phone number is required";
        }
        if (value.length != 10) {
          return "Phone must be 10 digits";
        }
        return null; // flutter_login might still require complexity, let's see
      },
      hideForgotPasswordButton: true, // New property in newer versions
    );
  }
}
