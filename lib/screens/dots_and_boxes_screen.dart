import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dots_and_boxes_model.dart';

class DotsAndBoxesScreen extends StatefulWidget {
  final bool isVsBot;
  final int gridSize;

  const DotsAndBoxesScreen({
    super.key,
    required this.isVsBot,
    this.gridSize = 8,
  });

  @override
  State<DotsAndBoxesScreen> createState() => _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  late DotsAndBoxesGame game;

  static const int maxTurnSeconds = 30;
  int remainingSeconds = maxTurnSeconds;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    game = DotsAndBoxesGame(gridSize: widget.gridSize);
    _startTurnTimer();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    remainingSeconds = maxTurnSeconds;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (game.isGameOver) return;
    HapticFeedback.heavyImpact();

    if (widget.isVsBot && game.currentTurn == DotPlayer.Player2) {
      _triggerBotMove();
    } else {
      setState(() {
        game.currentTurn = game.currentTurn == DotPlayer.Player1
            ? DotPlayer.Player2
            : DotPlayer.Player1;
      });
      _startTurnTimer();

      if (widget.isVsBot && game.currentTurn == DotPlayer.Player2) {
        _triggerBotMove();
      }
    }
  }

  void _onLineTapped({required bool isH, required int r, required int c}) {
    if (game.isGameOver) return;
    if (widget.isVsBot && game.currentTurn == DotPlayer.Player2) return;

    bool placed = isH ? game.claimHorizontal(r, c) : game.claimVertical(r, c);
    if (!placed) return;

    HapticFeedback.lightImpact();
    setState(() {});

    if (game.isGameOver) {
      _turnTimer?.cancel();
      _showGameOverDialog();
      return;
    }

    _startTurnTimer();

    if (widget.isVsBot && game.currentTurn == DotPlayer.Player2) {
      _triggerBotMove();
    }
  }

  void _triggerBotMove() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || game.isGameOver) return;

      final move = game.getBestBotMove();
      if (move != null) {
        bool isH = move['isH'];
        int r = move['r'];
        int c = move['c'];

        bool placed = isH ? game.claimHorizontal(r, c) : game.claimVertical(r, c);
        if (placed) {
          HapticFeedback.lightImpact();
          setState(() {});

          if (game.isGameOver) {
            _turnTimer?.cancel();
            _showGameOverDialog();
            return;
          }

          if (game.currentTurn == DotPlayer.Player2) {
            _triggerBotMove();
          } else {
            _startTurnTimer();
          }
        }
      }
    });
  }

  void _restartGame() {
    setState(() {
      game.reset();
    });
    _startTurnTimer();
  }

  void _showGameOverDialog() {
    HapticFeedback.heavyImpact();
    String title;
    Color accentColor;

    if (game.winner == DotPlayer.Player1) {
      title = 'بازیکن ۱ قهرمان شد! 🏆';
      accentColor = const Color(0xFFFFB800);
    } else if (game.winner == DotPlayer.Player2) {
      title = widget.isVsBot ? 'ربات بازی را برد! 🤖' : 'بازیکن ۲ قهرمان شد! 🏆';
      accentColor = const Color(0xFF00E5FF);
    } else {
      title = 'ماراتن مساوی شد! 🤝';
      accentColor = Colors.white;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161926),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accentColor.withOpacity(0.6), width: 1.5),
        ),
        title: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'نتیجه نهایی: ${game.p1Score} بر ${game.p2Score}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'تمام ${game.totalBoxes} مربع فتح شدند!',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('خروج به لابی', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('بازی مجدد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'نقطه‌خط • ${game.cols}×${game.rows} (${game.totalBoxes} مربع)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFB800)),
            tooltip: 'شروع مجدد',
            onPressed: _restartGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildScoreBoard(),
            const SizedBox(height: 8),
            _buildTimerAndTurnSection(),
            const Spacer(),
            _buildBoard(),
            const Spacer(),
            _buildHelperText(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    final isP1 = game.currentTurn == DotPlayer.Player1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerScore('بازیکن ۱ (زرد)', game.p1Score, const Color(0xFFFFB800), isP1),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildPlayerScore(
              widget.isVsBot ? 'ربات (آبی)' : 'بازیکن ۲ (آبی)',
              game.p2Score,
              const Color(0xFF00E5FF),
              !isP1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, Color color, bool isActive) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$score مربع',
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTimerAndTurnSection() {
    final isP1 = game.currentTurn == DotPlayer.Player1;
    final activeColor = isP1 ? const Color(0xFFFFB800) : const Color(0xFF00E5FF);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: remainingSeconds / maxTurnSeconds,
            strokeWidth: 2.8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          isP1 ? 'نوبت: بازیکن ۱ (زرد)' : (widget.isVsBot ? 'ربات در حال تفکر...' : 'نوبت: بازیکن ۲ (آبی)'),
          style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF161926),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double size = constraints.maxWidth;
              final double step = size / (game.gridSize - 1);
              final double dotRadius = 5.0;

              return Stack(
                children: [
                  // ۱. مربع‌های فتح‌شده
                  for (int r = 0; r < game.rows; r++)
                    for (int c = 0; c < game.cols; c++)
                      if (game.boxes[r][c] != null)
                        Positioned(
                          left: c * step + dotRadius,
                          top: r * step + dotRadius,
                          width: step - (dotRadius * 2),
                          height: step - (dotRadius * 2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: game.boxes[r][c] == DotPlayer.Player1
                                  ? const Color(0xFFFFB800).withOpacity(0.3)
                                  : const Color(0xFF00E5FF).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: game.boxes[r][c] == DotPlayer.Player1
                                      ? const Color(0xFFFFB800)
                                      : const Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ),
                        ),

                  // ۲. خطوط افقی
                  for (int r = 0; r < game.gridSize; r++)
                    for (int c = 0; c < game.cols; c++)
                      Positioned(
                        left: c * step + dotRadius,
                        top: r * step - 14,
                        width: step - (dotRadius * 2),
                        height: 28, // لمس راحت
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onLineTapped(isH: true, r: r, c: c),
                          child: Center(
                            child: Container(
                              height: game.hLines[r][c] ? 4.0 : 2.0,
                              decoration: BoxDecoration(
                                color: game.hLines[r][c]
                                    ? const Color(0xFFFF2A6D)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: game.hLines[r][c]
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF2A6D).withOpacity(0.8),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                      ),

                  // ۳. خطوط عمودی
                  for (int r = 0; r < game.rows; r++)
                    for (int c = 0; c < game.gridSize; c++)
                      Positioned(
                        left: c * step - 14,
                        top: r * step + dotRadius,
                        width: 28, // لمس راحت
                        height: step - (dotRadius * 2),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onLineTapped(isH: false, r: r, c: c),
                          child: Center(
                            child: Container(
                              width: game.vLines[r][c] ? 4.0 : 2.0,
                              decoration: BoxDecoration(
                                color: game.vLines[r][c]
                                    ? const Color(0xFFFF2A6D)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: game.vLines[r][c]
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF2A6D).withOpacity(0.8),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                      ),

                  // ۴. نقطه‌ها
                  for (int r = 0; r < game.gridSize; r++)
                    for (int c = 0; c < game.gridSize; c++)
                      Positioned(
                        left: c * step - dotRadius,
                        top: r * step - dotRadius,
                        child: Container(
                          width: dotRadius * 2,
                          height: dotRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.7),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHelperText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'روی فاصله بین نقطه‌ها بزنید تا خط کشیده شود. بستن هر خانه = حرکت دوباره!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}
