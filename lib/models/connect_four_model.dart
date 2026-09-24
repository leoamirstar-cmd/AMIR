enum Disc { Red, Yellow }

class ConnectFourGame {
  static const int rows = 6;
  static const int cols = 7;

  // ماتریس ۶ در ۷: سطر ۰ بالا و سطر ۵ پایین
  late List<List<Disc?>> board;

  Disc currentTurn = Disc.Red;
  Disc? winner;
  List<List<int>>? winningCells; // مختصات ۴ دیسک برنده [ [row, col], ... ]
  bool isDraw = false;
  bool isGameOver = false;

  ConnectFourGame() {
    reset();
  }

  void reset() {
    board = List.generate(rows, (_) => List.filled(cols, null));
    currentTurn = Disc.Red;
    winner = null;
    winningCells = null;
    isDraw = false;
    isGameOver = false;
  }

  /// انداختن دیسک در یک ستون (جاذبه: به پایین‌ترین خانه خالی می‌افتد)
  int dropDisc(int col) {
    if (isGameOver || col < 0 || col >= cols) return -1;

    // پیدا کردن عمیق‌ترین سطر خالی در این ستون
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == null) {
        board[r][col] = currentTurn;

        // بررسی برنده شدن ۴ تایی
        if (_checkWin(r, col, currentTurn)) {
          winner = currentTurn;
          isGameOver = true;
          return r;
        }

        // بررسی پر شدن کل تخته و مساوی
        if (_checkDraw()) {
          isDraw = true;
          isGameOver = true;
          return r;
        }

        // تغییر نوبت
        currentTurn = currentTurn == Disc.Red ? Disc.Yellow : Disc.Red;
        return r;
      }
    }
    return -1; // ستون پر است
  }

  bool _checkDraw() {
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == null) return false;
    }
    return true;
  }

  bool _checkWin(int r, int c, Disc disc) {
    // ۴ راستا برای بررسی: افقی، عمودی، مورب مثبت، مورب منفی
    final directions = [
      [0, 1],  // افقی
      [1, 0],  // عمودی
      [1, 1],  // مورب پایین-راست
      [1, -1], // مورب پایین-چپ
    ];

    for (var dir in directions) {
      int dr = dir[0];
      int dc = dir[1];
      List<List<int>> matched = [[r, c]];

      // حرکت در جهت جلو
      int step = 1;
      while (true) {
        int nr = r + dr * step;
        int nc = c + dc * step;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && board[nr][nc] == disc) {
          matched.add([nr, nc]);
          step++;
        } else {
          break;
        }
      }

      // حرکت در جهت معکوس
      step = 1;
      while (true) {
        int nr = r - dr * step;
        int nc = c - dc * step;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && board[nr][nc] == disc) {
          matched.add([nr, nc]);
          step++;
        } else {
          break;
        }
      }

      if (matched.length >= 4) {
        winningCells = matched;
        return true;
      }
    }
    return false;
  }

  /// هوش مصنوعی ربات برای انتخاب بهترین ستون
  int getBestBotMove() {
    List<int> validCols = [];
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == null) validCols.add(c);
    }
    if (validCols.isEmpty) return -1;

    // ۱. اگر ربات می‌تواند با این حرکت ۴ تایی کند و ببرد
    for (int c in validCols) {
      if (_simulateMove(c, Disc.Yellow)) return c;
    }

    // ۲. اگر بازیکن قرمز در آستانه ۴ تایی شدن است، حتماً بلاکش کند!
    for (int c in validCols) {
      if (_simulateMove(c, Disc.Red)) return c;
    }

    // ۳. اولویت ستون‌های مرکزی (ستون ۳ و بعد ۲ و ۴ قدرت استراتژیک دارند)
    final priorityOrder = [3, 2, 4, 1, 5, 0, 6];
    for (int c in priorityOrder) {
      if (validCols.contains(c)) return c;
    }

    validCols.shuffle();
    return validCols.first;
  }

  bool _simulateMove(int col, Disc disc) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == null) {
        board[r][col] = disc;
        bool win = _checkWin(r, col, disc);
        board[r][col] = null; // برگرداندن به حالت اول
        winningCells = null;
        return win;
      }
    }
    return false;
  }
}
