import 'package:flutter/material.dart';

const hopelyBlue = Color(0xFF004AC6);
const hopelyBlueDark = Color(0xFF2563EB);
const primaryFixed = Color(0xFFDBE1FF);
const surfaceHigh = Color(0xFFDCE9FF);
const surfaceContainer = Color(0xFFE5EEFF);
const surfaceHighest = Color(0xFFD3E4FE);
const lavender = Color(0xFFDBE1FF);
const lavenderSoft = Color(0xFFEFF4FF);
const skySoft = Color(0xFFEFF4FF);
const pillBlue = Color(0xFFDBE1FF);
const warningSoft = Color(0xFFFFDAD6);
const canvas = Color(0xFFF8F9FF);
const ink = Color(0xFF0B1C30);
const mutedInk = Color(0xFF434655);
const tertiaryInk = Color(0xFF485767);
const outline = Color(0xFF737686);
const outlineVariant = Color(0xFFC3C6D7);

const forest = hopelyBlue;
const mint = pillBlue;
const peach = warningSoft;

const hopelyCardShadow = [
  BoxShadow(
    color: Color(0x0D0053DB),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
];

ThemeData hopelyTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: hopelyBlue,
    onPrimary: Colors.white,
    secondary: Color(0xFF3755C3),
    onSecondary: Colors.white,
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: canvas,
    onSurface: ink,
    primaryContainer: hopelyBlueDark,
    onPrimaryContainer: Color(0xFFEEEFFF),
    secondaryContainer: Color(0xFF708CFD),
    onSecondaryContainer: Color(0xFF00217A),
    tertiary: tertiaryInk,
    onTertiary: Colors.white,
    errorContainer: warningSoft,
    onErrorContainer: Color(0xFF93000A),
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: skySoft,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
  ),
  scaffoldBackgroundColor: canvas,
  fontFamily: 'PlusJakartaSans',
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.36,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.18,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 26 / 16, color: ink),
    bodyMedium: TextStyle(fontSize: 15, height: 22 / 15, color: mutedInk),
    bodySmall: TextStyle(fontSize: 14, height: 20 / 14, color: mutedInk),
    labelLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.16,
      color: ink,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: ink,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.24,
      color: tertiaryInk,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xCCF8F9FF),
    foregroundColor: ink,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: ink,
      fontSize: 18,
      height: 26 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.18,
      fontFamily: 'PlusJakartaSans',
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: skySoft,
    selectedColor: hopelyBlueDark,
    labelStyle: const TextStyle(
      fontFamily: 'PlusJakartaSans',
      color: ink,
      fontWeight: FontWeight.w600,
    ),
    shape: const StadiumBorder(side: BorderSide.none),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: outlineVariant, fontSize: 16),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: hopelyBlue, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: hopelyBlueDark,
      foregroundColor: Colors.white,
      disabledBackgroundColor: primaryFixed,
      disabledForegroundColor: mutedInk,
      minimumSize: const Size(48, 52),
      elevation: 2,
      shadowColor: hopelyBlueDark.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: hopelyBlue,
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: primaryFixed),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: hopelyBlue,
      textStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white.withValues(alpha: 0.92),
    indicatorColor: Colors.transparent,
    elevation: 0,
    height: 64,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final active = states.contains(WidgetState.selected);
      return TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        height: 16 / 12,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
        color: active ? hopelyBlue : mutedInk,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final active = states.contains(WidgetState.selected);
      return IconThemeData(color: active ? hopelyBlue : mutedInk, size: 24);
    }),
  ),
);
