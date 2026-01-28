import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class LoadingPage extends StatefulWidget {
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool hasInternet = true;
  String? errorMessage;
  bool isChecking = false; // For showing progress during retry

  @override
  void initState() {
    super.initState();
    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    setState(() {
      isChecking = true;
      hasInternet = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 3)); // Splash screen delay

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasConnection = await InternetConnection().hasInternetAccess;

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        hasInternet = false;
        errorMessage =
            "No internet connection. Please check Wi-Fi or mobile data.";
        isChecking = false;
      });
      return;
    }

    if (!hasConnection) {
      setState(() {
        hasInternet = false;
        errorMessage = "Connected to network, but no Internet access.";
        isChecking = false;
      });
      return;
    }

    // Internet is available, check login status
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    setState(() {
      isChecking = false;
    });

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          // in case retry shows error and keyboard etc
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(75),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  "assets/Xeroxshoplogo.jpg",
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                '  RIT\n  Arcade',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '   Fast & Reliable Printing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Show loading spinner if checking internet and no errors
              if (hasInternet && isChecking)
                const CircularProgressIndicator(
                  color: Color(0xff102ed4),
                  strokeWidth: 5,
                ),

              // Show error message and retry button if no internet
              if (!hasInternet && !isChecking) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    errorMessage ?? "Unknown error",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _checkInternetAndNavigate,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    "Retry",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
