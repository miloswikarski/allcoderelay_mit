import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    listTileTheme: const ListTileThemeData(
      selectedColor: Color.fromARGB(255, 243, 194, 174),
      selectedTileColor: Color.fromARGB(255, 243, 194, 174),
      tileColor: Color.fromARGB(255, 243, 194, 174),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    listTileTheme: const ListTileThemeData(
      selectedColor: Color.fromARGB(255, 174, 220, 243),
      selectedTileColor: Color.fromARGB(255, 174, 220, 243),
      tileColor: Color.fromARGB(255, 174, 220, 243),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
