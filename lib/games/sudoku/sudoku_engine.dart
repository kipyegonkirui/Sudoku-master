import 'dart:math';

/// Sudoku engine for the Puzzle Pack app. Pure Dart, no Flutter imports,
/// so every rule can be unit tested. Grids are 9x9 lists, where 0 means empty.

enum SudokuDifficulty { easy, medium, hard }

extension SudokuDifficultyClues on SudokuDifficulty {
  /// Approximate number of given (pre-filled) cells to keep.
  int get targetClues => switch (this) {
        SudokuDifficulty.easy => 38,
        SudokuDifficulty.medium => 31,
        SudokuDifficulty.hard => 25,
      };
}

class SudokuPuzzle {
  final List<List<int>> puzzle; // givens only, 0 = empty
  final List<List<int>> solution; // the single valid completion

  const SudokuPuzzle(this.puzzle, this.solution);
}

class SudokuEngine {
  final Random _rng;

  SudokuEngine({Random? rng}) : _rng = rng ?? Random();

  /// Generates a puzzle with exactly one solution at the given difficulty.
  /// Cells are removed in random order, and a removal is kept only if the
  /// puzzle still has a unique solution.
  SudokuPuzzle generate(SudokuDifficulty difficulty) {
    final solution = _emptyGrid();
    _fill(solution);

    final puzzle = _copy(solution);
    final cells = List<int>.generate(81, (i) => i)..shuffle(_rng);
    var clues = 81;

    for (final cell in cells) {
      if (clues <= difficulty.targetClues) break;
      final r = cell ~/ 9;
      final c = cell % 9;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (countSolutions(puzzle, limit: 2) == 1) {
        clues--;
      } else {
        puzzle[r][c] = backup;
      }
    }

    return SudokuPuzzle(puzzle, solution);
  }

  /// Counts solutions up to [limit]. Returning early at the limit keeps
  /// generation fast, because uniqueness only needs to know "1 or more than 1".
  int countSolutions(List<List<int>> grid, {int limit = 2}) {
    return _count(_copy(grid), limit);
  }

  /// True if placing [value] at (row, col) breaks a row, column or 3x3 box rule.
  /// Used by the UI to highlight mistakes. The cell itself is ignored.
  bool conflicts(List<List<int>> grid, int row, int col, int value) {
    if (value == 0) return false;
    for (var i = 0; i < 9; i++) {
      if (i != col && grid[row][i] == value) return true;
      if (i != row && grid[i][col] == value) return true;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if ((r != row || c != col) && grid[r][c] == value) return true;
      }
    }
    return false;
  }

  /// True when every cell matches the stored solution.
  bool isComplete(List<List<int>> grid, List<List<int>> solution) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (grid[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  // ---- internal helpers -------------------------------------------------

  bool _fill(List<List<int>> grid) {
    final empty = _findEmpty(grid);
    if (empty == null) return true;
    final (r, c) = empty;
    final values = List<int>.generate(9, (i) => i + 1)..shuffle(_rng);
    for (final v in values) {
      if (_canPlace(grid, r, c, v)) {
        grid[r][c] = v;
        if (_fill(grid)) return true;
        grid[r][c] = 0;
      }
    }
    return false;
  }

  int _count(List<List<int>> grid, int limit) {
    final empty = _findEmpty(grid);
    if (empty == null) return 1;
    final (r, c) = empty;
    var total = 0;
    for (var v = 1; v <= 9; v++) {
      if (_canPlace(grid, r, c, v)) {
        grid[r][c] = v;
        total += _count(grid, limit);
        grid[r][c] = 0;
        if (total >= limit) return total;
      }
    }
    return total;
  }

  bool _canPlace(List<List<int>> grid, int row, int col, int value) {
    for (var i = 0; i < 9; i++) {
      if (grid[row][i] == value || grid[i][col] == value) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == value) return false;
      }
    }
    return true;
  }

  (int, int)? _findEmpty(List<List<int>> grid) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  List<List<int>> _emptyGrid() => List.generate(9, (_) => List.filled(9, 0));

  List<List<int>> _copy(List<List<int>> grid) =>
      [for (final row in grid) List<int>.from(row)];
}
