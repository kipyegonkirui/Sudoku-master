SUDOKU APP - FILES TO ADD

1. Open the sudoku_app folder in your project.
2. Delete test\widget_test.dart (the default counter test).
3. Copy the contents of this zip over the sudoku_app folder:
     lib\main.dart                              (replaces the default)
     lib\games\sudoku\sudoku_engine.dart        (new)
     lib\games\sudoku\sudoku_home.dart          (new)
     lib\games\sudoku\sudoku_game_screen.dart   (new)
     test\sudoku_engine_test.dart               (already there - same file)
4. Run:
     flutter test
     flutter run
5. Choose a difficulty, tap a cell, then tap a number.
   Erase clears a cell. Undo reverts your last change (it does not refund mistakes).
   Three mistakes ends the game.

If anything fails, copy the error message and send it back.
