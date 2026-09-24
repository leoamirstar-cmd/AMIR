enum DotPlayer { Player1, Player2 }

class DotsAndBoxesGame {
  final int gridSize;

  late int rows;
  late int cols;

  late List<List<bool>> hLines;
  late List<List<bool>> vLines;
  late List<List<DotPlayer?>> boxes;

  DotPlayer currentTurn = DotPlayer.Player1;
  int p1Score = 0;
  int p2Score = 0;
  bool isGameOver = false;
  DotPlayer? winner;

  DotsAndBoxesGame({this.gridSize = 8}) {
    reset();
  }

  void reset() {
    rows = gridSize - 1;
    cols = gridSize - 1;

    hLines = List.generate(gridSize, (_) => List.filled(cols, false));
    vLines = List.generate(rows, (_) => List.filled(gridSize, false));
    boxes = List.generate(rows, (_) => List.filled(cols, null));

    currentTurn = DotPlayer.Player1;
    p1Score = 0;
    p2Score = 0;
    isGameOver = false;
    winner = null;
  }

  int get totalBoxes => rows * cols;

  bool claimHorizontal(int r, int c) {
    if (isGameOver || hLines[r][c]) return false;

    hLines[r][c] = true;
    _handleLinePlaced(isH: true, r: r, c: c);
    return true;
  }

  bool claimVertical(int r, int c) {
    if (isGameOver || vLines[r][c]) return false;

    vLines[r][c] = true;
    _handleLinePlaced(isH: false, r: r, c: c);
    return true;
  }

  void _handleLinePlaced({required bool isH, required int r, required int c}) {
    int completedBoxes = 0;

    if (isH) {
      if (r > 0 && _isBoxComplete(r - 1, c)) {
        boxes[r - 1][c] = currentTurn;
        completedBoxes++;
      }
      if (r < rows && _isBoxComplete(r, c)) {
        boxes[r][c] = currentTurn;
        completedBoxes++;
      }
    } else {
      if (c > 0 && _isBoxComplete(r, c - 1)) {
        boxes[r][c - 1] = currentTurn;
        completedBoxes++;
      }
      if (c < cols && _isBoxComplete(r, c)) {
        boxes[r][c] = currentTurn;
        completedBoxes++;
      }
    }

    if (completedBoxes > 0) {
      if (currentTurn == DotPlayer.Player1) {
        p1Score += completedBoxes;
      } else {
        p2Score += completedBoxes;
      }

      if (p1Score + p2Score == totalBoxes) {
        isGameOver = true;
        if (p1Score > p2Score) {
          winner = DotPlayer.Player1;
        } else if (p2Score > p1Score) {
          winner = DotPlayer.Player2;
        } else {
          winner = null;
        }
      }
    } else {
      currentTurn = currentTurn == DotPlayer.Player1 ? DotPlayer.Player2 : DotPlayer.Player1;
    }
  }

  bool _isBoxComplete(int r, int c) {
    if (boxes[r][c] != null) return false;
    return hLines[r][c] && hLines[r + 1][c] && vLines[r][c] && vLines[r][c + 1];
  }

  int _countBoxSides(int r, int c) {
    int count = 0;
    if (hLines[r][c]) count++;
    if (hLines[r + 1][c]) count++;
    if (vLines[r][c]) count++;
    if (vLines[r][c + 1]) count++;
    return count;
  }

  Map<String, dynamic>? getBestBotMove() {
    if (isGameOver) return null;

    // ۱. اگر حرکتی وجود دارد که خانه‌ای را تکمیل می‌کند
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (boxes[r][c] == null && _countBoxSides(r, c) == 3) {
          if (!hLines[r][c]) return {'isH': true, 'r': r, 'c': c};
          if (!hLines[r + 1][c]) return {'isH': true, 'r': r + 1, 'c': c};
          if (!vLines[r][c]) return {'isH': false, 'r': r, 'c': c};
          if (!vLines[r][c + 1]) return {'isH': false, 'r': r, 'c': c + 1};
        }
      }
    }

    List<Map<String, dynamic>> safeMoves = [];
    List<Map<String, dynamic>> riskyMoves = [];

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < cols; c++) {
        if (!hLines[r][c]) {
          final move = {'isH': true, 'r': r, 'c': c};
          if (_isMoveSafe(isH: true, r: r, c: c)) {
            safeMoves.add(move);
          } else {
            riskyMoves.add(move);
          }
        }
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (!vLines[r][c]) {
          final move = {'isH': false, 'r': r, 'c': c};
          if (_isMoveSafe(isH: false, r: r, c: c)) {
            safeMoves.add(move);
          } else {
            riskyMoves.add(move);
          }
        }
      }
    }

    if (safeMoves.isNotEmpty) {
      safeMoves.shuffle();
      return safeMoves.first;
    }

    if (riskyMoves.isNotEmpty) {
      riskyMoves.shuffle();
      return riskyMoves.first;
    }

    return null;
  }

  bool _isMoveSafe({required bool isH, required int r, required int c}) {
    if (isH) {
      if (r > 0 && boxes[r - 1][c] == null && _countBoxSides(r - 1, c) == 2) return false;
      if (r < rows && boxes[r][c] == null && _countBoxSides(r, c) == 2) return false;
    } else {
      if (c > 0 && boxes[r][c - 1] == null && _countBoxSides(r, c - 1) == 2) return false;
      if (c < cols && boxes[r][c] == null && _countBoxSides(r, c) == 2) return false;
    }
    return true;
  }
}
