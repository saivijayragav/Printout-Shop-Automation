import 'customthemes/appbar_theme.dart';
import 'customthemes/bottomsheet.dart';
import 'customthemes/checkboxtheme.dart';
import 'customthemes/elevated_button_theme.dart';
import 'customthemes/outlinebuttontheme.dart';
import 'package:flutter/material.dart';
import 'customthemes/chip_theme.dart';
import 'customthemes/text_theme.dart';
import 'customthemes/textfieldtheme.dart';
class CustomTheme{
  CustomTheme._();

  static ThemeData theme = ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        primaryColor: Colors.purpleAccent,
        scaffoldBackgroundColor: const Color(0xFF021526),
        textTheme: CustomTextTheme.dark,
        appBarTheme: CustomAppBarTheme.appBarTheme,
        chipTheme: CustomChipTheme.darkChipTheme,
        checkboxTheme: CustomCheckBox.darkCheckBoxTheme,
        bottomSheetTheme: CustomButtonSheet.darkBottomSheet,
        elevatedButtonTheme: CustomElevatedButton.elevatedButtonTheme,
        outlinedButtonTheme: CustomOutlineButton.darkOutline,
        inputDecorationTheme: TextFieldTheme.darkInputDecorationTheme,
    );

}
