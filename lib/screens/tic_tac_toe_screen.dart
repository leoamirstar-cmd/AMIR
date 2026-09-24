import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tic_tac_toe_model.dart';

class InfiniteTicTacToeScreen extends StatefulWidget {
  final bool isVsBot;

  const InfiniteTicTacToeScreen({super.key, required this.isVsBot});

  @override
  State<InfiniteTicTacToeScreen> createState() => _InfiniteTicTacToeScreenState();
}

class _InfiniteTicTacToeScreenState extends State<InfiniteTicTacToeScreen>
    with SingleTickerProviderStateMixin {
  final InfiniteTicTacToeGame game = InfiniteTicTacToeGame();
  late AnimationController _pulseController;

  static const int targetWins = 2; // بهترین از ۳ راند (Best of 3)
  int xWins = 0;
  int oWins = 0;
  int currentRound = 1;

  // متغیرهای تایمر نوبت ۳۰ ثانیه‌ای
  static const int maxTurnSeconds = 30;
  int remainingSeconds = maxTurnSeconds;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    // کنترلر انیمیشن تپش و چشمک‌زن
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startTurnTimer();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _pulseController.dispose();
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
          if (remainingSeconds == 5) {
            HapticFeedback.mediumImpact();
          }
        } else {
          // زمان تمام شد -> تغییر خودکار نوبت
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (game.isGameOver) return;

    HapticFeedback.heavyImpact();

    if (widget.isVsBot && game.currentTurn == Player.O) {
      // اگر نوبت ربات بود و زمان تمام شد، سریع یک حرکت می‌زند
      int botMove = game.getBestBotMove();
      if (botMove != -1) {
        _executeMove(botMove);
      }
    } else {
      // نوبت بازیکن سوخت و به نفر بعدی واگذار شد
      setState(() {
        game.currentTurn = game.currentTurn == Player.X ? Player.O : Player.X;
      });
      _startTurnTimer();

      // اگر بعد از سوختن نوبت، نوبت ربات شد
      if (widget.isVsBot && game.currentTurn == Player.O) {
        _triggerBotMove();
      }
    }
  }

  void _onCellTapped(int index) {
    if (game.isGameOver || game.board[index] != null) return;
    if (widget.isVsBot && game.currentTurn == Player.O) return;

    _executeMove(index);
  }

  void _executeMove(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      game.makeMove(index);
    });

    if (game.isGameOver) {
      _turnTimer?.cancel();
      _handleRoundEnd();
      return;
    }

    // ریست تایمر برای نوبت بعدی
    _startTurnTimer();

    if (widget.isVsBot && game.currentTurn == Player.O) {
      _triggerBotMove();
    }
  }

  void _triggerBotMove() {
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || game.isGameOver) return;
      int botMove = game.getBestBotMove();
      if (botMove != -1) {
        _executeMove(botMove);
      }
    });
  }

  void _handleRoundEnd() {
    HapticFeedback.heavyImpact();
    setState(() {
      if (game.winner == Player.X) xWins++;
      if (game.winner == Player.O) oWins++;
    });

    if (xWins >= targetWins || oWins >= targetWins) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showMatchWinnerDialog();
      });
    }
  }

  void _startNextRound() {
    setState(() {
      currentRound++;
      game.reset();
    });
    _startTurnTimer();
  }

  void _resetEntireMatch() {
    setState(() {
      xWins = 0;
      oWins = 0;
      currentRound = 1;
      game.reset();
    });
    _startTurnTimer();
  }

  void _showMatchWinnerDialog() {
    final bool isXWinner = xWins >= targetWins;
    final winnerTitle = isXWinner
        ? 'بازیکن X قهرمان شد! 🏆'
        : (widget.isVsBot ? 'ربات مسابقه را برد! 🤖' : 'بازیکن O قهرمان شد! 🏆');
    final accentColor = isXWinner ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161926),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accentColor.withOpacity(0.5), width: 1.5),
        ),
        title: Center(
          child: Text(
            winnerTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'نتیجه نهایی مسابقه: $xWins بر $oWins',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'مسابقه ۳ رانده به پایان رسید.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
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
              _resetEntireMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('مسابقه جدید', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'راند $currentRound از ۳ (اولین نفر به ۲ برد)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            tooltip: 'شروع مجدد مسابقه',
            onPressed: _resetEntireMatch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            _buildScoreBoard(),
            const SizedBox(height: 12),
            _buildTimerAndTurnSection(),
            const Spacer(),
            _buildBoard(),
            const Spacer(),
            if (game.isGameOver && xWins < targetWins && oWins < targetWins)
              _buildNextRoundButton()
            else
              _buildHelperText(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerScore('بازیکن X', xWins, const Color(0xFF00E5FF), game.currentTurn == Player.X),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildPlayerScore(
              widget.isVsBot ? 'ربات O' : 'بازیکن O',
              oWins,
              const Color(0xFFFF2A6D),
              game.currentTurn == Player.O,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String name, int wins, Color color, bool isActive) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
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
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(targetWins, (index) {
            final isAchieved = index < wins;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAchieved ? color : Colors.transparent,
                border: Border.all(color: color, width: 1.5),
                boxShadow: isAchieved
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
            );
          }),
        ),
      ],
    );
  }

  /// بخش ترکیبی تایمر ۳۰ ثانیه‌ای و اعلام نوبت
  Widget _buildTimerAndTurnSection() {
    if (game.isGameOver) {
      final winnerName = game.winner == Player.X
          ? 'برنده راند: بازیکن X 🎯'
          : (widget.isVsBot ? 'برنده راند: ربات O 🤖' : 'برنده راند: بازیکن O 🎯');
      final color = game.winner == Player.X ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(
          winnerName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }

    final isX = game.currentTurn == Player.X;
    final activeColor = isX ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D);
    final isUrgent = remainingSeconds <= 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // تایمر دایره‌ای ۳۰ ثانیه‌ای
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: remainingSeconds / maxTurnSeconds,
                strokeWidth: 3.5,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent ? Colors.redAccent : activeColor,
                ),
              ),
            ),
            Text(
              '$remainingSeconds',
              style: TextStyle(
                color: isUrgent ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Text(
          isX ? 'نوبت حرکت: بازیکن X' : (widget.isVsBot ? 'ربات در حال حرکت...' : 'نوبت حرکت: بازیکن O'),
          style: TextStyle(
            color: activeColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161926),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return _buildCell(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final player = game.board[index];
    final isWinningCell = game.winningLine?.contains(index) ?? false;
    final isFading = game.isFadingPiece(index);

    return GestureDetector(
      onTap: () => _onCellTapped(index),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // محاسبات افکت تپنده و چشمک‌زن قوی
          double opacity = 1.0;
          double scale = 1.0;

          if (isFading && !game.isGameOver) {
            opacity = 0.4 + (_pulseController.value * 0.6); // تغییر شفافیت بین ۰.۴ تا ۱.۰
            scale = 0.90 + (_pulseController.value * 0.15); // تپش اندازه مهره بین ۹۰٪ تا ۱۰۵٪
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWinningCell
                    ? Colors.amberAccent
                    : (isFading
                        ? Colors.orangeAccent.withOpacity(0.5 + (_pulseController.value * 0.5))
                        : Colors.white.withOpacity(0.05)),
                width: isWinningCell ? 3 : (isFading ? 2.5 : 1),
              ),
              boxShadow: isWinningCell
                  ? [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.6),
                        blurRadius: 16,
                      )
                    ]
                  : (isFading && !game.isGameOver
                      ? [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.35 * _pulseController.value),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : []),
            ),
            child: Center(
              child: player == null
                  ? null
                  : Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: player == Player.X
                            ? _buildXIcon(isWinningCell, isFading)
                            : _buildOIcon(isWinningCell, isFading),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildXIcon(bool isWinning, bool isFading) {
    final color = isFading ? Colors.orangeAccent : const Color(0xFF00E5FF);
    return Icon(
      Icons.close_rounded,
      size: 58,
      color: color,
      shadows: [
        Shadow(
          color: color.withOpacity(isWinning ? 1.0 : 0.6),
          blurRadius: isWinning ? 25 : 12,
        ),
      ],
    );
  }

  Widget _buildOIcon(bool isWinning, bool isFading) {
    final color = isFading ? Colors.orangeAccent : const Color(0xFFFF2A6D);
    return Icon(
      Icons.circle_outlined,
      size: 50,
      color: color,
      shadows: [
        Shadow(
          color: color.withOpacity(isWinning ? 1.0 : 0.6),
          blurRadius: isWinning ? 25 : 12,
        ),
      ],
    );
  }

  Widget _buildNextRoundButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ElevatedButton.icon(
        onPressed: _startNextRound,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
        label: const Text(
          'شروع راند بعدی ➔',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildHelperText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.access_time_rounded, size: 16, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'هر بازیکن ۳۰ ثانیه برای حرکت فرصت دارد. مهره در حال حذف، به رنگ نارنجی تپش می‌کند!',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
