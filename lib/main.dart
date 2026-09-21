import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'game_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // قفل کردن بازی در حالت عمودی برای خوش‌دست بودن روی موبایل
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
            // نوار وضعیت بالای بازی (بازیکن جاری و اطلاعات)
            _buildTopBar(),

            // صفحه اصلی بازی و بورد چوبی
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0, // نسبت تصویر مربعی دقیق بورد
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // لایه ۱: عکس پس‌زمینه بورد چوبی
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/board.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // فال‌بک شیک در صورت لود نشدن عکس
                                  return Container(
                                    color: const Color(0xFF3E2312),
                                    child: const Center(
                                      child: Text(
                                        'لطفاً عکس board.png را در assets/images قرار دهید',
                                        style: TextStyle(color: Colors.amber),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // لایه ۲: رندر مهره‌های چوبی با سایه و نور سه‌بعدی
                            Positioned.fill(
                              child: CustomPaint(
                                painter: LuxuryCheckersPainter(
                                  game: game,
                                  selectedPointIndex: selectedPointIndex,
                                ),
                              ),
                            ),

                            // لایه ۳: دکمه‌های نامرئی لمس خانه‌ها
                            Positioned.fill(
                              child: _buildTouchOverlay(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // پنل کنترل پایین (تاس، دکمه ریختن، تغییر دست)
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
            tooltip: 'شروع مجدد',
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
          // نمایش تاس‌ها
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

          // دکمه تاس ریختن
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
              backgroundColor: const Color(0xFFD4AF37), // طلایی لوکس
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

  Widget _buildTouchOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            // شناسایی خانه لمس شده
            final localPos = details.localPosition;
            final point = _findPointFromCoordinates(localPos, constraints.biggest);
            if (point != null) {
              setState(() {
                selectedPointIndex = point;
              });
            }
          },
        );
      },
    );
  }

  int? _findPointFromCoordinates(Offset pos, Size size) {
    // تخمین موقعیت ۲۴ دندانه متناسب با تصویر بورد
    // ۶ خانه در ۴ ربع اصلی
    final isTop = pos.dy < size.height / 2;
    final isLeft = pos.dx < size.width / 2;
    // محاسبه ساده برای تست تاچ
    return null;
  }
}

/// نقاش پیشرفته مهره‌های چوبی سنتی با سایه، برجستگی و های‌لایت سه‌بعدی
class LuxuryCheckersPainter extends CustomPainter {
  final BackgammonGame game;
  final int? selectedPointIndex;

  LuxuryCheckersPainter({
    required this.game,
    this.selectedPointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ابعاد و مارجین‌های متناسب با عکس board.png
    final boardWidth = size.width;
    final boardHeight = size.height;

    // محدوده ستون‌های بورد با در نظر گرفتن حاشیه‌های چوب و لولای وسط
    final outerMarginX = boardWidth * 0.085;
    final centerBarWidth = boardWidth * 0.085;
    final usableHalfWidth = (boardWidth - (outerMarginX * 2) - centerBarWidth) / 2;
    final pointWidth = usableHalfWidth / 6;

    final checkerRadius = pointWidth * 0.44;

    // مختصات ۲۴ خانه (۱۲ خانه بالا، ۱۲ خانه پایین)
    for (int i = 0; i < 24; i++) {
      final point = game.points[i];
      if (point.count == 0 || point.color == null) continue;

      final isTop = i >= 12;
      double baseX = 0;

      // محاسبه مختصات X متناسب با چرخش استاندارد تخته
      if (isTop) {
        // ۱۲ تا ۲۳ در بالا
        if (i <= 17) {
          // بالا سمت راست
          baseX = outerMarginX + (i - 12) * pointWidth + (pointWidth / 2);
        } else {
          // بالا سمت چپ (بعد از لولای وسط)
          baseX = outerMarginX + usableHalfWidth + centerBarWidth + (i - 18) * pointWidth + (pointWidth / 2);
        }
      } else {
        // ۰ تا ۱۱ در پایین
        if (i <= 5) {
          // پایین سمت چپ
          baseX = outerMarginX + usableHalfWidth + centerBarWidth + (5 - i) * pointWidth + (pointWidth / 2);
        } else {
          // پایین سمت راست
          baseX = outerMarginX + (11 - i) * pointWidth + (pointWidth / 2);
        }
      }

      // رسم ستون مهره‌ها روی هم
      for (int c = 0; c < point.count; c++) {
        // هم‌پوشانی ملایم اگر تعداد مهره‌ها بیشتر از ۵ تا بود
        final spacing = checkerRadius * 1.85;
        final double baseY = isTop
            ? (boardHeight * 0.08) + (c * spacing)
            : (boardHeight * 0.92) - (c * spacing);

        _drawLuxuryChecker(
          canvas,
          Offset(baseX, baseY),
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
    // ۱. سایه طبیعی مهره روی چوب (Drop Shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isSelected ? 0.6 : 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 8 : 4);

    canvas.drawCircle(
      center.translate(0, isSelected ? 6 : 3),
      radius,
      shadowPaint,
    );

    // ۲. گرادیانت چوب اصلی مهره (گردوی تیره یا افرای روشن)
    final baseGradient = isWhite
        ? const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFFFF7EA), Color(0xFFDECAAC), Color(0xFF9E8565)],
            stops: [0.0, 0.7, 1.0],
          )
        : const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF4A3425), Color(0xFF28190E), Color(0xFF120B06)],
            stops: [0.0, 0.6, 1.0],
          );

    final basePaint = Paint()
      ..shader = baseGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, basePaint);

    // ۳. حلقه فرورفتگی سنتی وسط مهره (شیار خراطی‌شده سنتی ایرانی)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..color = isWhite
          ? const Color(0xFF8C7150).withOpacity(0.5)
          : Colors.black.withOpacity(0.7);

    canvas.drawCircle(center, radius * 0.6, ringPaint);

    // ۴. های‌لایت نور براق لبه بالای مهره (Specular Reflection)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isWhite ? 0.8 : 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * 0.88, highlightPaint);

    // ۵. حلقه انتخاب شدن مهره در صورت لمس
    if (isSelected) {
      final selectPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = const Color(0xFFFFD700);
      canvas.drawCircle(center, radius + 2, selectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LuxuryCheckersPainter oldDelegate) {
    return true;
  }
}
