enum Player { X, O }

class Move {
  final int index;
  final Player player;

  Move({required this.index, required this.player});
}

class InfiniteTicTacToeGame {
  // تخته ۹ تایی (۰ تا ۸)
  final List<Player?> board = List.filled(9, null);

  // صف حرکات برای هر بازیکن (حداکثر ۳ مهره)
  final List<int> xMoves = [];
  final List<int> oMoves = [];

  Player currentTurn = Player.X;
  Player? winner;
  List<int>? winningLine;
  bool isGameOver = false;

  void reset() {
    board.fillRange(0, 9, null);
    xMoves.clear;
    oMoves.clear;
    currentTurn = Player.X;
    winner = null;
    winningLine = null;
    isGameOver = false;
  }

  // چک کردن اینکه آیا یک خانه همان مهره‌ای است که در حرکت بعدی حذف می‌شود
  bool isFadingPiece(int index) {
    if (currentTurn == Player.X && xMoves.length == 3 && xMoves.first == index) {
      return true;
    }
    if (currentTurn == Player.O && oMoves.length == 3 && oMoves.first == index) {
      return true;
    }
    return false;
  }

  bool makeMove(int index) {
    if (isGameOver || board[index] != null) return false;

    final currentQueue = currentTurn == Player.X ? xMoves : oMoves;

    // اگر بازیکن ۳ مهره دارد، قدیمی‌ترین مهره‌اش پاک می‌شود
    if (currentQueue.length == 3) {
      int removedIndex = currentQueue.removeAt(0);
      board[removedIndex] = null;
    }

    // اضافه کردن مهره جدید
    currentQueue.add(index);
    board[index] = currentTurn;

    // بررسی برد
    if (_checkWin(currentTurn)) {
      winner = currentTurn;
      isGameOver = true;
      return true;
    }

    // تغییر نوبت
    currentTurn = currentTurn == Player.X ? Player.O : Player.X;
    return true;
  }

  bool _checkWin(Player player) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // سطری
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // ستونی
      [0, 4, 8], [2, 4, 6]             // مورب
    ];

    for (var line in lines) {
      if (board[line[0]] == player &&
          board[line[1]] == player &&
          board[line[2]] == player) {
        winningLine = line;
        return true;
      }
    }
    return false;
  }

  // هوش مصنوعی ربات (هنگامی که نوبت O است)
  int getBestBotMove() {
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (board[i] == null) available.add(i);
    }
    if (available.isEmpty) return -1;

    // ۱. اگر ربات می‌تواند در این حرکت برنده شود
    for (int idx in available) {
      if (_simulateWin(idx, Player.O, oMoves)) return idx;
    }

    // ۲. دفاع در برابر برنده شدن بازیکن X در حرکت بعدی
    for (int idx in available) {
      if (_simulateWin(idx, Player.X, xMoves)) return idx;
    }

    // ۳. مرکز صفحه اولویت دارد
    if (available.contains(4)) return 4;

    // ۴. گوشه‌ها در اولویت بعدی
    List<int> corners = [0, 2, 6, 8].where((c) => available.contains(c)).toList();
    if (corners.isNotEmpty) {
      corners.shuffle();
      return corners.first;
    }

    // ۵. انتخاب رندوم از خانه‌های باقی‌مانده
    available.shuffle();
    return available.first;
  }

  bool _simulateWin(int moveIndex, Player p, List<int> queue) {
    List<Player?> tempBoard = List.from(board);
    List<int> tempQueue = List.from(queue);

    if (tempQueue.length == 3) {
      int removed = tempQueue.removeAt(0);
      tempBoard[removed] = null;
    }
    tempBoard[moveIndex] = p;

    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var line in lines) {
      if (tempBoard[line[0]] == p &&
          tempBoard[line[1]] == p &&
          tempBoard[line[2]] == p) {
        return true;
      }
    }
    return false;
  }
}
