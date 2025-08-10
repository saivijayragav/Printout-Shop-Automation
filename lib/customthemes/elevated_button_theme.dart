import 'package:flutter/material.dart';

class CustomElevatedButton{
  CustomElevatedButton._();

  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFFE2E2B6),
          disabledForegroundColor: Colors.grey,
          disabledBackgroundColor: Colors.grey,
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600, ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      )
  );

}