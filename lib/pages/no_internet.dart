import 'package:flutter/material.dart';

class No_internet extends StatelessWidget {
  const No_internet({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Text(
        'No Internet Connection',
        style: TextStyle(fontSize: 20, color: Colors.red),
      ),
    ));
  }
}
