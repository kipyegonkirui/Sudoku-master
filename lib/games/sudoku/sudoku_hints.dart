import 'sudoku_engine.dart';

/// A suggested move with a plain-English reason, so the player learns
/// the technique rather than just being given a number.
class SudokuHint {
  final int row;
  final int col;
  final int value;
  final String explanation;

  const SudokuHint({
    required this.row,
    required this.col,
    required this.value,
    required this.explanation,
  });
}

class SudokuHintFinder {
  final SudokuEngine engine;

  const SudokuHintFinder(this.engine);

  /// Numbers that could still go in an empty square, given the current grid.
  Set<int> candidates(List<List<int>> grid, int r, int c) {
    if (grid[r][c] != 0) return {};
    return {
      for (var v = 1; v <= 9; v++)
        if (!engine.conflicts(grid, r, c, v)) v,
    };
  }

  /// Returns the next hint, or null if the board is already complete.
  SudokuHint? find(List<List<int>> grid, List<List<int>> solution) {
    // 1. Naked single: only one number fits this square.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cand = candidates(grid, r, c);
        if (cand.length == 1 && cand.first == solution[r][c]) {
          return SudokuHint(
            row: r,
            col: c,
            value: cand.first,
            explanation:
                'Every other number is already ruled out for this square by its '
                'row, column and box, so it must be ${cand.first}.',
          );
        }
      }
    }

    // 2. Hidden single: a number has only one possible square in a unit.
    for (final (label, cells) in _units()) {
      for (var v = 1; v <= 9; v++) {
        if (cells.any((p) => grid[p.$1][p.$2] == v)) continue;
        final spots = cells
            .where((p) => candidates(grid, p.$1, p.$2).contains(v))
            .toList();
        if (spots.length == 1) {
          final (r, c) = spots.first;
          if (solution[r][c] == v) {
            return SudokuHint(
              row: r,
              col: c,
              value: v,
              explanation:
                  '$v has nowhere else to go in $label, so it must go in this square.',
            );
          }
        }
      }
    }

    // 3. Fallback: no simple deduction, so reveal the answer for an empty square.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          return SudokuHint(
            row: r,
            col: c,
            value: solution[r][c],
            explanation:
                'This one needs a longer chain of reasoning. The answer is '
                '${solution[r][c]}. Check the numbers already in its row, column and box.',
          );
        }
      }
    }
    return null;
  }

  List<(String, List<(int, int)>)> _units() {
    final units = <(String, List<(int, int)>)>[];
    for (var i = 0; i < 9; i++) {
      units.add(('row ${i + 1}', [for (var c = 0; c < 9; c++) (i, c)]));
    }
    for (var i = 0; i < 9; i++) {
      units.add(('column ${i + 1}', [for (var r = 0; r < 9; r++) (r, i)]));
    }
    for (var b = 0; b < 9; b++) {
      final br = (b ~/ 3) * 3;
      final bc = (b % 3) * 3;
      units.add((
        'that 3×3 box',
        [for (var r = br; r < br + 3; r++) for (var c = bc; c < bc + 3; c++) (r, c)],
      ));
    }
    return units;
  }
}