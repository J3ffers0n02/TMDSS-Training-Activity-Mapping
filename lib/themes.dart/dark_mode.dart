import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: Colors.black,
    primary: Colors.grey.shade900,
    secondary: Colors.grey.shade800,
    tertiary: Colors.grey.shade300,
    inversePrimary: Colors.grey.shade500,
    inverseSurface: Colors.white,
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.grey[300],
    displayColor: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.black
);