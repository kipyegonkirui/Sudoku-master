import 'package:flutter/material.dart';
import 'games/sudoku/sudoku_home.dart';

void main() => runApp(const SudokuApp());

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3949AB),
        useMaterial3: true,
      ),
      home: const SudokuHome(),
    );
  }
}
