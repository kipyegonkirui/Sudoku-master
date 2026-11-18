import 'package:flutter/material.dart';
import 'sudoku_engine.dart';

class SudokuGameScreen extends StatefulWidget {
  final SudokuDifficulty difficulty;
  const SudokuGameScreen({super.key, required this.difficulty});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  static const int maxMistakes = 3;

  final _engine = SudokuEngine();
  late SudokuPuzzle _puzzle;
  late List<List<int>> _grid;
  int? _selRow;
  int? _selCol;
  int _mistakes = 0;
  bool _won = false;
  bool _lost = false;
  final List<List<List<int>>> _history = [];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  String get _title {
    final name = widget.difficulty.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  void _newGame() {
    _puzzle = _engine.generate(widget.difficulty);
    _grid = [for (final r in _puzzle.puzzle) List<int>.from(r)];
    _selRow = null;
    _selCol = null;
    _mistakes = 0;
    _won = false;
    _lost = false;
    _history.clear();
  }

  void _enter(int value) {
    if (_selRow == null || _won || _lost) return;
    final r = _selRow!;
    final c = _selCol!;
    if (_puzzle.puzzle[r][c] != 0) return; // pre-filled cells can't change

    setState(() {
      _history.add([for (final row in _grid) List<int>.from(row)]);
      _grid[r][c] = value;
      if (value != 0 && value != _puzzle.solution[r][c]) {
        _mistakes++;
        if (_mistakes >= maxMistakes) _lost = true;
      }
      if (_engine.isComplete(_grid, _puzzle.solution)) _won = true;
    });

    if (_lost) {
      _showEndDialog(
        title: 'Out of mistakes',
        message: 'You made $maxMistakes mistakes. Try another puzzle?',
      );
    } else if (_won) {
      _showEndDialog(
        title: 'Solved!',
        message: 'Well done. You finished with $_mistakes mistake(s).',
      );
    }
  }

  void _showEndDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Menu'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(_newGame);
            },
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_history.isEmpty || _won || _lost) return;
    setState(() => _grid = _history.removeLast());
  }

  Widget _cell(int r, int c) {
    final scheme = Theme.of(context).colorScheme;
    final given = _puzzle.puzzle[r][c] != 0;
    final value = _grid[r][c];
    final selected = r == _selRow && c == _selCol;
    final wrong = value != 0 && value != _puzzle.solution[r][c];
    final conflict = value != 0 && _engine.conflicts(_grid, r, c, value);

    Color bg = Colors.white;
    if (selected) {
      bg = scheme.primaryContainer;
    } else if (wrong || conflict) {
      bg = scheme.errorContainer;
    }

    return GestureDetector(
      onTap: () => setState(() {
        _selRow = r;
        _selCol = c;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: BorderSide(
              width: (c == 2 || c == 5) ? 2 : 0.5,
              color: Colors.black54,
            ),
            bottom: BorderSide(
              width: (r == 2 || r == 5) ? 2 : 0.5,
              color: Colors.black54,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value == 0 ? '' : '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: given ? FontWeight.bold : FontWeight.normal,
            color: given ? Colors.black : scheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _won
        ? 'Solved!'
        : _lost
            ? 'Out of mistakes'
            : 'Mistakes: $_mistakes / $maxMistakes';

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(status, style: const TextStyle(fontSize: 16)),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: Column(
                  children: [
                    for (var r = 0; r < 9; r++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < 9; c++)
                              Expanded(child: _cell(r, c)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var n = 1; n <= 9; n++)
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _enter(n),
                      child: Text('$n', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _enter(0),
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('Erase'),
                ),
                OutlinedButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(_newGame),
                  icon: const Icon(Icons.refresh),
                  label: const Text('New'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}