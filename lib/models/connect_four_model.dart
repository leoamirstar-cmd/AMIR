enum Disc { Red, Yellow }

class ConnectFourGame {
  static const int rows = 6;
  static const int cols = 7;

  late List<List<Disc?>> board;

  Disc currentTurn = Disc.Red;
  Disc? winner;
  List<List<int>>? winningCells;
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

  /// انداختن مهره در ستون (جاذبه)
  int dropDisc(int col) {
    if (isGameOver || col < 0 || col >= cols) return -1;

    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == null) {
        board[r][col] = currentTurn;

        if (_checkWin(r, col, currentTurn)) {
          winner = currentTurn;
          isGameOver = true;
          return r;
        }

        if (_checkDraw()) {
          isDraw = true;
          isGameOver = true;
          return r;
        }

        currentTurn = currentTurn == Disc.Red ? Disc.Yellow : Disc.Red;
        return r;
      }
    }
    return -1;
  }

  bool _checkDraw() {
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == null) return false;
    }
    return true;
  }

  bool _checkWin(int r, int c, Disc disc) {
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

  // ==========================================
  // هوش مصنوعی پیشرفته (الگوریتم Minimax و ارزیابی استراتژیک)
  // ==========================================

  int getBestBotMove() {
    List<int> validCols = [];
    for (int c = 0; c < cols; c++) {
      if (board[0][c] == null) validCols.add(c);
    }
    if (validCols.isEmpty) return -1;

    // ۱. حرکت پیروزی‌بخش آنی ربات (۴تایی فوری)
    for (int c in validCols) {
      if (_simulateWinMove(c, Disc.Yellow)) return c;
    }

    // ۲. دفاع فوری در برابر ۴تایی شدن حریف (بلاک فوری)
    for (int c in validCols) {
      if (_simulateWinMove(c, Disc.Red)) return c;
    }

    // ۳. فیلتر کردن ستون‌های تله‌دار:
    // (حرکاتی که اگر ربات بزند، خانه بالایش باعث برد حریف در دور بعد می‌شود)
    List<int> safeCols = [];
    for (int c in validCols) {
      int r = _getLowestEmptyRow(c);
      if (r > 0) {
        // آیا اگر ما در r مهره بگذاریم، حریف با گذاشتن در r-1 می‌برد؟
        board[r][c] = Disc.Yellow;
        bool givesOpponentWin = _checkWin(r - 1, c, Disc.Red);
        board[r][c] = null;
        winningCells = null;

        if (!givesOpponentWin) {
          safeCols.add(c);
        }
      } else {
        safeCols.add(c); // بالاترین سطر است
      }
    }

    // اگر ستون امن وجود داشت، فقط از بین امن‌ها انتخاب کند
    List<int> candidates = safeCols.isNotEmpty ? safeCols : validCols;

    // ۴. امتیازدهی پیشرفته به موقعیت‌ها (Heuristic Evaluation)
    int bestScore = -999999;
    int bestCol = candidates.first;

    for (int c in candidates) {
      int r = _getLowestEmptyRow(c);
      board[r][c] = Disc.Yellow;
      int score = _evaluateBoard();
      board[r][c] = null;
      winningCells = null;

      // امتیاز ویژه کنترل مرکز
      if (c == 3) score += 40;
      if (c == 2 || c == 4) score += 20;

      if (score > bestScore) {
        bestScore = score;
        bestCol = c;
      }
    }

    return bestCol;
  }

  int _getLowestEmptyRow(int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == null) return r;
    }
    return -1;
  }

  bool _simulateWinMove(int col, Disc disc) {
    int r = _getLowestEmptyRow(col);
    if (r == -1) return false;

    board[r][col] = disc;
    bool win = _checkWin(r, col, disc);
    board[r][col] = null;
    winningCells = null;
    return win;
  }

  /// امتیازدهی به تمام پنجره‌های ۴تایی افقی، عمودی و مورب
  int _evaluateBoard() {
    int score = 0;

    // افقی
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols - 3; c++) {
        score += _evaluateWindow([board[r][c], board[r][c + 1], board[r][c + 2], board[r][c + 3]]);
      }
    }

    // عمودی
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows - 3; r++) {
        score += _evaluateWindow([board[r][c], board[r + 1][c], board[r + 2][c], board[r + 3][c]]);
      }
    }

    // مورب مثبت (پایین به بالا)
    for (int r = 3; r < rows; r++) {
      for (int c = 0; c < cols - 3; c++) {
        score += _evaluateWindow([board[r][c], board[r - 1][c + 1], board[r - 2][c + 2], board[r - 3][c + 3]]);
      }
    }

    // مورب منفی (بالا به پایین)
    for (int r = 0; r < rows - 3; r++) {
      for (int c = 0; c < cols - 3; c++) {
        score += _evaluateWindow([board[r][c], board[r + 1][c + 1], board[r + 2][c + 2], board[r + 3][c + 3]]);
      }
    }

    return score;
  }

  int _evaluateWindow(List<Disc?> window) {
    int botCount = window.where((d) => d == Disc.Yellow).length;
    int humanCount = window.where((d) => d == Disc.Red).length;
    int emptyCount = window.where((d) => d == null).length;

    int score = 0;

    if (botCount == 4) {
      score += 10000;
    } else if (botCount == 3 && emptyCount == 1) {
      score += 120; // شانس عالی برای برد ربات
    } else if (botCount == 2 && emptyCount == 2) {
      score += 15;
    }

    if (humanCount == 3 && emptyCount == 1) {
      score -= 250; // خطر جدی باخت ربات؛ حتماً بلاک کند
    } else if (humanCount == 2 && emptyCount == 2) {
      score -= 25;
    }

    return score;
  }
}
