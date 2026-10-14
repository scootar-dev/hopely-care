import 'package:flutter/material.dart';

const hopelyBlue = Color(0xFF004AC6);
const hopelyBlueDark = Color(0xFF2563EB);
const lavender = Color(0xFFE8E3FF);
const lavenderSoft = Color(0xFFF6F2FF);
const skySoft = Color(0xFFEFF4FF);
const pillBlue = Color(0xFFDDE7FF);
const warningSoft = Color(0xFFFFE2DC);
const canvas = Color(0xFFF8F9FF);
const ink = Color(0xFF0B1C30);
const mutedInk = Color(0xFF526079);

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
  fontFamily: 'PlusJakartaSans',
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 1.14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 1.22,
      fontWeight: FontWeight.w700,
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
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: ink,
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      fontFamily: 'PlusJakartaSans',
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: lavender,
    selectedColor: hopelyBlue,
    labelStyle: const TextStyle(
      fontFamily: 'PlusJakartaSans',
      color: ink,
      fontWeight: FontWeight.w700,
    ),
    shape: const StadiumBorder(side: BorderSide.none),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(14),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: hopelyBlue, width: 1.4),
      borderRadius: BorderRadius.circular(14),
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: hopelyBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 56),
      elevation: 2,
      shadowColor: hopelyBlue.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: hopelyBlue,
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: pillBlue,
    elevation: 0,
    shadowColor: Colors.black.withValues(alpha: 0.08),
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        color: ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const WidgetStatePropertyAll(IconThemeData(color: ink)),
  ),
);
