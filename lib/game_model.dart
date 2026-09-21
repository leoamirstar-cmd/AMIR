import 'dart:math';

enum PlayerColor { white, black }

class CheckerPoint {
  final int index; // 0 to 23
  int count;
  PlayerColor? color;

  CheckerPoint({
    required this.index,
    this.count = 0,
    this.color,
  });
}

class BackgammonGame {
  // 24 خانه استاندارد تخته نرد
  late List<CheckerPoint> points;
  
  // مهره‌های خورده‌شده (روی بار / لولا وسط)
  int whiteBar = 0;
  int blackBar = 0;

  // مهره‌های خارج‌شده (Bear-off)
  int whiteBorneOff = 0;
  int blackBorneOff = 0;

  // نوبت بازیکن جاری
  PlayerColor currentTurn = PlayerColor.white;

  // وضعیت تاس‌ها
  List<int> dice = [];
  List<int> remainingMoves = [];
  bool isDiceRolled = false;

  BackgammonGame() {
    initStandardBoard();
  }

  // چیدمان رسمی و استاندارد بین‌المللی تخته نرد
  void initStandardBoard() {
    points = List.generate(24, (i) => CheckerPoint(index: i));

    // چیدمان ۲۴ خانه:
    // ۲ مهره سفید در خانه ۲۳
    points[23].count = 2;
    points[23].color = PlayerColor.white;

    // ۵ مهره مشکی در خانه ۱۸
    points[18].count = 5;
    points[18].color = PlayerColor.black;

    // ۳ مهره مشکی در خانه ۱۲
    points[12].count = 3;
    points[12].color = PlayerColor.black;

    // ۵ مهره سفید در خانه ۷
    points[7].count = 5;
    points[7].color = PlayerColor.white;

    // ۵ مهره مشکی در خانه ۵
    points[5].count = 5;
    points[5].color = PlayerColor.black;

    // ۳ مهره سفید در خانه ۱۱
    points[11].count = 3;
    points[11].color = PlayerColor.white;

    // ۵ مهره سفید در خانه ۱۶
    points[16].count = 5;
    points[16].color = PlayerColor.white;

    // ۲ مهره مشکی در خانه ۰
    points[0].count = 2;
    points[0].color = PlayerColor.black;

    whiteBar = 0;
    blackBar = 0;
    whiteBorneOff = 0;
    blackBorneOff = 0;
    currentTurn = PlayerColor.white;
    dice = [];
    remainingMoves = [];
    isDiceRolled = false;
  }

  // ریختن تاس با محاسبه جفت
  void rollDice() {
    final random = Random();
    int d1 = random.nextInt(6) + 1;
    int d2 = random.nextInt(6) + 1;
    dice = [d1, d2];
    isDiceRolled = true;

    if (d1 == d2) {
      // قانون جفت: ۴ حرکت
      remainingMoves = [d1, d1, d1, d1];
    } else {
      remainingMoves = [d1, d2];
    }
  }

  // تغییر نوبت
  void switchTurn() {
    currentTurn = (currentTurn == PlayerColor.white)
        ? PlayerColor.black
        : PlayerColor.white;
    dice = [];
    remainingMoves = [];
    isDiceRolled = false;
  }
}
