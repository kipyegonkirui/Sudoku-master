import 'package:flutter/material.dart';
import 'sudoku_engine.dart';
import 'sudoku_game_screen.dart';

class SudokuHome extends StatelessWidget {
  const SudokuHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in SudokuDifficulty.values)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SudokuGameScreen(difficulty: d),
                      ),
                    ),
                    child: Text(
                      '${d.name[0].toUpperCase()}${d.name.substring(1)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
