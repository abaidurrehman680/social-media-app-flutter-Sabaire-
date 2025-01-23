import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Constants {
  // App-related strings
  static String appName = "Sabaire";

  // New Color Scheme
  static const Color lightPrimary = Color(0xff29b8a5); // Teal color for primary
  static const Color darkPrimary = Color(0xff004D40); // Darker teal for accent
  static const Color lightAccent = Color(0xffc85531); // Orange for accents
  static const Color darkAccent = Color(0xffb69287); // Lighter orange for dark mode
  static const Color lightBG = Color(0xffECEFF1); // Light grey background for light mode
  static const Color darkBG = Color(0xff263238); // Dark grey background for dark mode
  static const Color textColor = Color(0xff37474F); // Dark grey text color
  static const Color textDarkColor = Color(0xffffffff); // White text color for dark mode

  // Light theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: lightAccent,
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      elevation: 0,
      color: lightBG,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0.0,
      backgroundColor: lightBG,
      iconTheme: const IconThemeData(color: Colors.black),
      toolbarTextStyle: GoogleFonts.nunito(
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleTextStyle: GoogleFonts.nunito(
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      background: lightBG,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBG,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: darkAccent,
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      elevation: 0,
      color: darkBG,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0.0,
      backgroundColor: darkBG,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarTextStyle: GoogleFonts.nunito(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleTextStyle: GoogleFonts.nunito(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkAccent,
      background: darkBG,
    ),
  );
}
