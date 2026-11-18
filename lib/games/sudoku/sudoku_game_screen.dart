import 'package:flutter/material.dart';
import 'sudoku_engine.dart';
import 'sudoku_feedback.dart';
import 'sudoku_hints.dart';

class SudokuGameScreen extends StatefulWidget {
  final SudokuDifficulty difficulty;
  const SudokuGameScreen({super.key, required this.difficulty});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen>
    with SingleTickerProviderStateMixin {
  static const int maxMistakes = 3;
  static const int maxHints = 3;
  static const double _bigSize = 96;
  static const Color _sweepColor = Color(0xFFC5DDF8);
  static const TextStyle _flightStyle = TextStyle(
    fontSize: _bigSize,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0xFF42A5F5), blurRadius: 24),
      Shadow(color: Color(0xFF0D47A1), offset: Offset(3, 4), blurRadius: 2),
    ],
  );

  final _engine = SudokuEngine();
  final _feedback = SudokuFeedback();
  late SudokuPuzzle _puzzle;
  late List<List<int>> _grid;
  int? _selRow;
  int? _selCol;
  int _mistakes = 0;
  int _hintsLeft = maxHints;
  final Set<(int, int)> _hinted = {};
  final Set<(int, int)> _sweep = {};
  bool _won = false;
  bool _lost = false;
  final List<List<List<int>>> _history = [];

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _flying = false;
  int _flR = 0;
  int _flC = 0;
  int _flV = 0;

  @override
  void initState() {
    super.initState();
    _flight.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _flying = false);
      }
    });
    _newGame();
  }

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
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
    _hintsLeft = maxHints;
    _hinted.clear();
    _sweep.clear();
    _won = false;
    _lost = false;
    _history.clear();
    _flying = false;
    _flight.reset();
  }

  // ---- unit helpers (row, column, box) ----

  List<List<(int, int)>> _unitsContaining(int r, int c) {
    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    return [
      [for (var i = 0; i < 9; i++) (r, i)],
      [for (var i = 0; i < 9; i++) (i, c)],
      [
        for (var rr = br; rr < br + 3; rr++)
          for (var cc = bc; cc < bc + 3; cc++) (rr, cc),
      ],
    ];
  }

  bool _unitDone(List<(int, int)> cells) => cells.every(
        (p) => _grid[p.$1][p.$2] == _puzzle.solution[p.$1][p.$2],
      );

  /// Lights the squares of a completed line one after another, then fades
  /// each one back to its normal colour.
  void _sweepUnit(List<(int, int)> cells) {
    for (var i = 0; i < cells.length; i++) {
      final p = cells[i];
      Future.delayed(Duration(milliseconds: i * 45), () {
        if (!mounted) return;
        setState(() => _sweep.add(p));
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _sweep.remove(p));
        });
      });
    }
  }

  // ---- actions ----

  void _enter(int value) {
    if (_selRow == null || _won || _lost || _flying) return;
    final r = _selRow!;
    final c = _selCol!;
    if (_puzzle.puzzle[r][c] != 0) return; // pre-filled cells can't change
    if (_hinted.contains((r, c))) return; // hinted cells are permanent

    final units = _unitsContaining(r, c);
    final wasDone = [for (final u in units) _unitDone(u)];
    final wrongEntry = value != 0 && value != _puzzle.solution[r][c];

    setState(() {
      _history.add([for (final row in _grid) List<int>.from(row)]);
      _grid[r][c] = value;
      if (wrongEntry) {
        _mistakes++;
        if (_mistakes >= maxMistakes) _lost = true;
      }
      if (_engine.isComplete(_grid, _puzzle.solution)) _won = true;
    });

    if (value != 0) {
      if (wrongEntry) {
        _feedback.mistake();
      } else if (_won) {
        _feedback.win();
      } else {
        _feedback.correct();
        var completedAny = false;
        for (var i = 0; i < units.length; i++) {
          if (!wasDone[i] && _unitDone(units[i])) {
            completedAny = true;
            _sweepUnit(units[i]);
          }
        }
        if (completedAny) _feedback.unitComplete();
      }
    }

    _showEndIfNeeded();
  }

  void _hint() {
    if (_hintsLeft == 0 || _won || _lost || _flying) return;
    final hint = SudokuHintFinder(_engine).find(_grid, _puzzle.solution);
    if (hint == null) return;

    setState(() {
      _hintsLeft--;
      _grid[hint.row][hint.col] = hint.value;
      _hinted.add((hint.row, hint.col));
      _history.clear(); // a hint can't be undone, and undo can't pass it
      _selRow = hint.row;
      _selCol = hint.col;
      _flying = true;
      _flR = hint.row;
      _flC = hint.col;
      _flV = hint.value;
      if (_engine.isComplete(_grid, _puzzle.solution)) _won = true;
    });

    _flight.forward(from: 0);
    if (_won) {
      _feedback.win();
    } else {
      _feedback.hint();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hint.explanation),
        duration: const Duration(seconds: 6),
      ),
    );
    _showEndIfNeeded();
  }

  void _undo() {
    if (_history.isEmpty || _won || _lost || _flying) return;
    setState(() => _grid = _history.removeLast());
  }

  void _showEndIfNeeded() {
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

  // ---- widgets ----

  /// The big blue number that pops up, then flies into its square.
  Widget _hintOverlay(double side) {
    final cell = side / 9;
    final target = Offset((_flC + 0.5) * cell, (_flR + 0.5) * cell);
    final center = Offset(side / 2, side / 2);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _flight,
        builder: (context, _) {
          final t = _flight.value;
          final entry = Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
          final fly =
              Curves.easeInOutCubic.transform(((t - 0.45) / 0.55).clamp(0.0, 1.0));
          final pos = Offset.lerp(center, target, fly)!;
          final scale = entry + (0.25 - entry) * fly;
          final dim = entry.clamp(0.0, 1.0) * (1 - fly) * 0.35;

          return Stack(
            children: [
              IgnorePointer(
                child: Container(color: Color.fromRGBO(0, 0, 0, dim)),
              ),
              Positioned(
                left: pos.dx - _bigSize / 2,
                top: pos.dy - _bigSize / 2,
                width: _bigSize,
                height: _bigSize,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: entry.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: Center(child: Text('$_flV', style: _flightStyle)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(int r, int c) {
    final scheme = Theme.of(context).colorScheme;
    final given = _puzzle.puzzle[r][c] != 0;
    final hinted = _hinted.contains((r, c));
    final value = _grid[r][c];
    final selected = r == _selRow && c == _selCol;
    final wrong = value != 0 && value != _puzzle.solution[r][c];
    final conflict = value != 0 && _engine.conflicts(_grid, r, c, value);

    Color bg = Colors.white;
    if (hinted) {
      bg = const Color(0xFFC8E6C9);
    } else if (selected) {
      bg = scheme.primaryContainer;
    } else if (_sweep.contains((r, c))) {
      bg = _sweepColor;
    } else if (wrong || conflict) {
      bg = scheme.errorContainer;
    }

    Color textColor = scheme.primary;
    if (given) {
      textColor = Colors.black;
    } else if (hinted) {
      textColor = const Color(0xFF1B5E20);
    }

    final flyingHere = _flying && r == _flR && c == _flC;
    final text = (value == 0 || flyingHere) ? '' : '$value';

    return GestureDetector(
      onTap: () => setState(() {
        _selRow = r;
        _selCol = c;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: (given || hinted) ? FontWeight.bold : FontWeight.normal,
            color: textColor,
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
    final canHint = _hintsLeft > 0 && !_won && !_lost && !_flying;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Sound',
            icon: Icon(_feedback.soundOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () =>
                setState(() => _feedback.soundOn = !_feedback.soundOn),
          ),
          IconButton(
            tooltip: 'Vibration',
            icon: Icon(
              Icons.vibration,
              color: _feedback.vibrationOn ? null : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _feedback.vibrationOn = !_feedback.vibrationOn),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(status, style: const TextStyle(fontSize: 16)),
                  OutlinedButton.icon(
                    onPressed: canHint ? _hint : null,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: Text('Hint ($_hintsLeft)'),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = box.maxWidth;
                    return Stack(
                      children: [
                        Positioned.fill(
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
                        if (_flying) _hintOverlay(side),
                      ],
                    );
                  },
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