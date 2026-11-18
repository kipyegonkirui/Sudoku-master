import 'dart:math';

import 'package:test/test.dart';

import '../lib/games/sudoku/sudoku_engine.dart';

bool _isValidSolution(List<List<int>> g) {
  bool unitOk(Iterable<int> values) =>
      values.toSet().length == 9 && values.every((v) => v >= 1 && v <= 9);

  for (var i = 0; i < 9; i++) {
    if (!unitOk(g[i])) return false;
    if (!unitOk([for (var r = 0; r < 9; r++) g[r][i]])) return false;
  }
  for (var br = 0; br < 9; br += 3) {
    for (var bc = 0; bc < 9; bc += 3) {
      final box = [
        for (var r = br; r < br + 3; r++)
          for (var c = bc; c < bc + 3; c++) g[r][c],
      ];
      if (!unitOk(box)) return false;
    }
  }
  return true;
}

int _clues(List<List<int>> g) =>
    g.expand((row) => row).where((v) => v != 0).length;

void main() {
  group('generation', () {
    for (final difficulty in SudokuDifficulty.values) {
      test('${difficulty.name} puzzle has a unique solution', () {
        final engine = SudokuEngine(rng: Random(42));
        final result = engine.generate(difficulty);
        expect(engine.countSolutions(result.puzzle, limit: 2), 1);
      });

      test('${difficulty.name} solution is a valid completed grid', () {
        final engine = SudokuEngine(rng: Random(7));
        final result = engine.generate(difficulty);
        expect(_isValidSolution(result.solution), isTrue);
      });

      test('${difficulty.name} givens match the solution', () {
        final engine = SudokuEngine(rng: Random(3));
        final result = engine.generate(difficulty);
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (result.puzzle[r][c] != 0) {
              expect(result.puzzle[r][c], result.solution[r][c]);
            }
          }
        }
      });

      test('${difficulty.name} clue count is close to target', () {
        final engine = SudokuEngine(rng: Random(11));
        final result = engine.generate(difficulty);
        final clues = _clues(result.puzzle);
        // Uniqueness can stop removal early, so allow some slack above target.
        expect(clues, greaterThanOrEqualTo(difficulty.targetClues));
        expect(clues, lessThanOrEqualTo(difficulty.targetClues + 8));
      });
    }

    test('different seeds produce different puzzles', () {
      final a = SudokuEngine(rng: Random(1)).generate(SudokuDifficulty.medium);
      final b = SudokuEngine(rng: Random(2)).generate(SudokuDifficulty.medium);
      expect(a.solution, isNot(equals(b.solution)));
    });
  });

  group('solution counting', () {
    test('empty grid has more than one solution', () {
      final empty = List.generate(9, (_) => List.filled(9, 0));
      expect(SudokuEngine(rng: Random(0)).countSolutions(empty, limit: 2), 2);
    });

    test('a completed grid has exactly one solution', () {
      final engine = SudokuEngine(rng: Random(5));
      final solved = engine.generate(SudokuDifficulty.easy).solution;
      expect(engine.countSolutions(solved), 1);
    });
  });

  group('conflicts', () {
    final engine = SudokuEngine(rng: Random(0));
    final grid = List.generate(9, (_) => List.filled(9, 0));
    grid[0][0] = 5; // row 0, col 0, box 0

    test('same row conflicts', () {
      expect(engine.conflicts(grid, 0, 8, 5), isTrue);
    });

    test('same column conflicts', () {
      expect(engine.conflicts(grid, 8, 0, 5), isTrue);
    });

    test('same box conflicts', () {
      expect(engine.conflicts(grid, 2, 2, 5), isTrue);
    });

    test('unrelated cell does not conflict', () {
      expect(engine.conflicts(grid, 4, 4, 5), isFalse);
    });

    test('clearing a cell (value 0) never conflicts', () {
      expect(engine.conflicts(grid, 0, 0, 0), isFalse);
    });

    test('a cell does not conflict with itself', () {
      expect(engine.conflicts(grid, 0, 0, 5), isFalse);
    });
  });

  group('completion', () {
    test('matching grid is complete', () {
      final engine = SudokuEngine(rng: Random(9));
      final solution = engine.generate(SudokuDifficulty.hard).solution;
      final copy = [for (final row in solution) List<int>.from(row)];
      expect(engine.isComplete(copy, solution), isTrue);
    });

    test('grid with one wrong or empty cell is not complete', () {
      final engine = SudokuEngine(rng: Random(9));
      final solution = engine.generate(SudokuDifficulty.hard).solution;
      final copy = [for (final row in solution) List<int>.from(row)];
      copy[4][4] = 0;
      expect(engine.isComplete(copy, solution), isFalse);
    });
  });
}
