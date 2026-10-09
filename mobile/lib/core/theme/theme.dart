import 'package:flutter/material.dart';

const hopelyBlue = Color(0xFF0E5AE8);
const hopelyBlueDark = Color(0xFF0647C7);
const lavender = Color(0xFFEDE7FF);
const lavenderSoft = Color(0xFFF6F2FF);
const skySoft = Color(0xFFEFF3FF);
const pillBlue = Color(0xFFDDE7FF);
const warningSoft = Color(0xFFFFE2DC);
const canvas = Color(0xFFFBF9FF);
const ink = Color(0xFF12172B);
const mutedInk = Color(0xFF697089);

const forest = hopelyBlue;
const mint = pillBlue;
const peach = warningSoft;

ThemeData hopelyTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: hopelyBlue,
    primary: hopelyBlue,
    secondary: const Color(0xFF7B45E8),
    surface: Colors.white,
    error: const Color(0xFFD33131),
  ),
  scaffoldBackgroundColor: canvas,
  fontFamily: 'DejaVuSans',
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 29,
      height: 1.14,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 23,
      height: 1.22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.35,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: mutedInk),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: mutedInk),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: ink,
      fontSize: 24,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      fontFamily: 'DejaVuSans',
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: lavender,
    selectedColor: hopelyBlue,
    labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
    shape: const StadiumBorder(side: BorderSide.none),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F6FF),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(22),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: hopelyBlue, width: 1.4),
      borderRadius: BorderRadius.circular(22),
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: hopelyBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 56),
      elevation: 6,
      shadowColor: hopelyBlue.withOpacity(0.28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: hopelyBlue,
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: pillBlue,
    elevation: 10,
    shadowColor: Colors.black.withOpacity(0.08),
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600),
    ),
    iconTheme: const WidgetStatePropertyAll(IconThemeData(color: ink)),
  ),
);
