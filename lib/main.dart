import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        scaffoldBackgroundColor: const Color(0xFF120904),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.9),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            // ۱. بورد چوبی خام با منبت‌کاری دور و لولا
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/board.png',
                                fit: BoxFit.fill,
                              ),
                            ),

                            // ۲. لایه مثلث‌های خاتم‌کاری دقیق
                            Positioned.fill(
                              child: CustomPaint(
                                painter: KhatamTrianglesPainter(),
                              ),
                            ),

                            // ۳. لایه مهره‌های چوبی طبیعی و واقعی
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _buildCheckersLayer(constraints.biggest);
                                },
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
        color: const Color(0xFF1A0E06),
        border: Border(
          bottom: BorderSide(color: Colors.amber.withOpacity(0.25), width: 1),
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
                isWhite ? 'نوبت: سفید (افرا)' : 'نوبت: مشکی (گردو)',
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
      color: const Color(0xFF160B05),
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

  /// لایه چیدمان مهره‌های طبیعی با عکس واقعی
  Widget _buildCheckersLayer(Size size) {
    final W = size.width;
    final H = size.height;

    // هندسه دقیق کادر داخلی تخته خام (بدون در نظر گرفتن منبت دور و شیارها)
    final leftFieldStart = W * 0.175;
    final leftFieldEnd = W * 0.465;
    final rightFieldStart = W * 0.535;
    final rightFieldEnd = W * 0.825;

    final leftStep = (leftFieldEnd - leftFieldStart) / 6.0;
    final rightStep = (rightFieldEnd - rightFieldStart) / 6.0;

    final checkerSize = leftStep * 0.92;
    final topBaseY = H * 0.095;
    final bottomBaseY = H * 0.905 - checkerSize;
    final checkerOverlap = checkerSize * 0.82;

    List<Widget> checkerWidgets = [];

    for (int i = 0; i < 24; i++) {
      final point = game.points[i];
      if (point.count == 0 || point.color == null) continue;

      final isTop = i >= 12;
      double posX = 0;

      if (isTop) {
        if (i <= 17) {
          final col = 17 - i;
          posX = leftFieldStart + (col * leftStep) + ((leftStep - checkerSize) / 2);
        } else {
          final col = i - 18;
          posX = rightFieldStart + (col * rightStep) + ((rightStep - checkerSize) / 2);
        }
      } else {
        if (i <= 5) {
          final col = i;
          posX = rightFieldStart + (col * rightStep) + ((rightStep - checkerSize) / 2);
        } else {
          final col = 11 - i;
          posX = leftFieldStart + (col * leftStep) + ((leftStep - checkerSize) / 2);
        }
      }

      for (int c = 0; c < point.count; c++) {
        final posY = isTop
            ? topBaseY + (c * checkerOverlap)
            : bottomBaseY - (c * checkerOverlap);

        final isWhite = point.color == PlayerColor.white;

        checkerWidgets.add(
          Positioned(
            left: posX,
            top: posY,
            width: checkerSize,
            height: checkerSize,
            child: _buildRealisticCheckerWidget(isWhite),
          ),
        );
      }
    }

    return Stack(children: checkerWidgets);
  }

  Widget _buildRealisticCheckerWidget(bool isWhite) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isWhite
          // مهره چوب افرای طبیعی (عکس اصلی)
          ? Image.asset(
              'assets/images/checker.png',
              fit: BoxFit.contain,
            )
          // مهره چوب گردوی تیره (با فیلتر رنگی گرم چوب کهنسال)
          : ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.28, 0, 0, 0, 15,
                0, 0.18, 0, 0, 8,
                0, 0, 0.12, 0, 4,
                0, 0, 0, 1.0, 0,
              ]),
              child: Image.asset(
                'assets/images/checker.png',
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

/// نقاش مثلث‌های اصیل خاتم‌کاری با نوک باریک و حاشیه‌های طلایی
class KhatamTrianglesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    final leftFieldStart = W * 0.175;
    final leftFieldEnd = W * 0.465;
    final rightFieldStart = W * 0.535;
    final rightFieldEnd = W * 0.825;

    final leftStep = (leftFieldEnd - leftFieldStart) / 6.0;
    final rightStep = (rightFieldEnd - rightFieldStart) / 6.0;

    final triangleHeight = H * 0.38;
    final topY = H * 0.085;
    final bottomY = H * 0.915;

    // ۱۲ مثلث بالا
    for (int i = 0; i < 6; i++) {
      // چپ بالا
      final x1 = leftFieldStart + (i * leftStep);
      final x2 = x1 + leftStep;
      _drawKhatamTriangle(canvas, x1, topY, x2, topY, (x1 + x2) / 2, topY + triangleHeight, i % 2 == 0);

      // راست بالا
      final rx1 = rightFieldStart + (i * rightStep);
      final rx2 = rx1 + rightStep;
      _drawKhatamTriangle(canvas, rx1, topY, rx2, topY, (rx1 + rx2) / 2, topY + triangleHeight, i % 2 == 1);
    }

    // ۱۲ مثلث پایین
    for (int i = 0; i < 6; i++) {
      // چپ پایین
      final x1 = leftFieldStart + (i * leftStep);
      final x2 = x1 + leftStep;
      _drawKhatamTriangle(canvas, x1, bottomY, x2, bottomY, (x1 + x2) / 2, bottomY - triangleHeight, i % 2 == 1);

      // راست پایین
      final rx1 = rightFieldStart + (i * rightStep);
      final rx2 = rx1 + rightStep;
      _drawKhatamTriangle(canvas, rx1, bottomY, rx2, bottomY, (rx1 + rx2) / 2, bottomY - triangleHeight, i % 2 == 0);
    }
  }

  void _drawKhatamTriangle(
    Canvas canvas,
    double x1, double y1,
    double x2, double y2,
    double tipX, double tipY,
    bool isLight,
  ) {
    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(tipX, tipY)
      ..close();

    // رنگ و گرادیانت چوب افرا یا گردوی خاتم
    final gradient = isLight
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF3E7D3).withOpacity(0.85),
              const Color(0xFFDCC4A5).withOpacity(0.9),
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF381F13).withOpacity(0.85),
              const Color(0xFF221109).withOpacity(0.9),
            ],
          );

    final fillPaint = Paint()
      ..shader = gradient.createShader(path.getBounds())
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // خط حاشیه طلایی-برنجی ظریف دور هر مثلث
    final strokePaint = Paint()
      ..color = const Color(0xFFC8A155).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
