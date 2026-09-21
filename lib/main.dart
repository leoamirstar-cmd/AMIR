import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'game_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const LuxuryBackgammonApp());
}

class LuxuryBackgammonApp extends StatelessWidget {
  const LuxuryBackgammonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تخته نرد پارسی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF140C07),
      ),
      home: const BackgammonGameScreen(),
    );
  }
}

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({super.key});

  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  final BackgammonGame game = BackgammonGame();
  int? selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/board.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: CalibratedCheckersPainter(
                                  game: game,
                                  selectedPointIndex: selectedPointIndex,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isWhite = game.currentTurn == PlayerColor.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E130B),
        border: Border(
          bottom: BorderSide(color: Colors.amber.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite ? const Color(0xFFF3E7D3) : const Color(0xFF261910),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isWhite ? 'نوبت: مهره سفید (افرا)' : 'نوبت: مهره مشکی (گردو)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: () {
              setState(() {
                game.initStandardBoard();
                selectedPointIndex = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1A1009),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              if (game.dice.isNotEmpty) ...[
                _buildDiceWidget(game.dice[0]),
                const SizedBox(width: 10),
                _buildDiceWidget(game.dice[1]),
              ] else
                const Text(
                  'تاس را بریزید',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                game.rollDice();
              });
            },
            icon: const Icon(Icons.casino, color: Colors.black),
            label: const Text(
              'پرتاب تاس',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceWidget(int value) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EC),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// نقاش دقیق کالیبره‌شده روی مثلث‌های عکس board.png
class CalibratedCheckersPainter extends CustomPainter {
  final BackgammonGame game;
  final int? selectedPointIndex;

  CalibratedCheckersPainter({
    required this.game,
    this.selectedPointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // کالیبراسیون دقیق بر اساس تصویر board.png شما:
    // سمت چپ: حاشیه بیرونی + شیار جمع‌آوری مهره = حدود ۱۶.۵٪ عرض
    final leftTrayEnd = W * 0.165;
    // لولای وسط: بین ۴۷.۵٪ تا ۵۲.۵٪ عرض
    final leftFieldEnd = W * 0.475;
    final rightFieldStart = W * 0.525;
    // سمت راست: شیار جمع‌آوری مهره = از ۸۳.۵٪ تا انتها
    final rightFieldEnd = W * 0.835;

    // عرض هر خانه (۶ مثلث در سمت چپ، ۶ مثلث در سمت راست)
    final leftPointWidth = (leftFieldEnd - leftTrayEnd) / 6.0;
    final rightPointWidth = (rightFieldEnd - rightFieldStart) / 6.0;

    // اندازه قطر مهره (کمی کوچک‌تر از عرض مثلث تا توی دلش بشینه)
    final checkerRadius = leftPointWidth * 0.44;

    // موقعیت Y شروع مهره‌ها از بالا و پایین (دقیقاً روی انحنای مثلث‌ها)
    final topBaseY = H * 0.135;
    final bottomBaseY = H * 0.865;
    final checkerSpacing = checkerRadius * 1.85;

    for (int i = 0; i < 24; i++) {
      final point = game.points[i];
      if (point.count == 0 || point.color == null) continue;

      final isTop = i >= 12;
      double centerX = 0;

      if (isTop) {
        // خانه‌های ۱۲ تا ۲۳ (بالای تخته)
        if (i <= 17) {
          // ۱۲ تا ۱۷: سمت چپ بالا (از وسط به سمت چپ)
          final indexInBlock = 17 - i;
          centerX = leftTrayEnd + (indexInBlock * leftPointWidth) + (leftPointWidth / 2);
        } else {
          // ۱۸ تا ۲۳: سمت راست بالا (از وسط به سمت راست)
          final indexInBlock = i - 18;
          centerX = rightFieldStart + (indexInBlock * rightPointWidth) + (rightPointWidth / 2);
        }
      } else {
        // خانه‌های ۰ تا ۱۱ (پایین تخته)
        if (i <= 5) {
          // ۰ تا ۵: سمت راست پایین
          final indexInBlock = i;
          centerX = rightFieldStart + (indexInBlock * rightPointWidth) + (rightPointWidth / 2);
        } else {
          // ۶ تا ۱۱: سمت چپ پایین
          final indexInBlock = 11 - i;
          centerX = leftTrayEnd + (indexInBlock * leftPointWidth) + (leftPointWidth / 2);
        }
      }

      // رسم مهره‌ها
      for (int c = 0; c < point.count; c++) {
        final centerY = isTop
            ? topBaseY + (c * checkerSpacing)
            : bottomBaseY - (c * checkerSpacing);

        _drawLuxuryChecker(
          canvas,
          Offset(centerX, centerY),
          checkerRadius,
          point.color == PlayerColor.white,
          selectedPointIndex == i && c == point.count - 1,
        );
      }
    }
  }

  void _drawLuxuryChecker(
    Canvas canvas,
    Offset center,
    double radius,
    bool isWhite,
    bool isSelected,
  ) {
    // ۱. سایه نرم چوب
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isSelected ? 0.6 : 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 8 : 4);

    canvas.drawCircle(
      center.translate(0, isSelected ? 5 : 3),
      radius,
      shadowPaint,
    );

    // ۲. گرادیانت چوب مهره (افرا یا گردو)
    final baseGradient = isWhite
        ? const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFFFF8EE), Color(0xFFE5D5BC), Color(0xFFA68E70)],
            stops: [0.0, 0.65, 1.0],
          )
        : const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF533B2C), Color(0xFF2C1B10), Color(0xFF140B06)],
            stops: [0.0, 0.6, 1.0],
          );

    final basePaint = Paint()
      ..shader = baseGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, basePaint);

    // ۳. شیار سنتی وسط مهره
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..color = isWhite
          ? const Color(0xFF947B5A).withOpacity(0.55)
          : Colors.black.withOpacity(0.75);

    canvas.drawCircle(center, radius * 0.58, ringPaint);

    // ۴. های‌لایت براق سه‌بعدی
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isWhite ? 0.85 : 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.88, highlightPaint);

    if (isSelected) {
      final selectPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0xFFFFD700);
      canvas.drawCircle(center, radius + 2, selectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
