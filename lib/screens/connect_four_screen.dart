import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/connect_four_model.dart';

class ConnectFourScreen extends StatefulWidget {
  final bool isVsBot;

  const ConnectFourScreen({super.key, required this.isVsBot});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen>
    with SingleTickerProviderStateMixin {
  final ConnectFourGame game = ConnectFourGame();
  late AnimationController _winPulseController;

  static const int targetWins = 2; // بهترین از ۳ مسابقه
  int redWins = 0;
  int yellowWins = 0;
  int currentRound = 1;

  static const int maxTurnSeconds = 30;
  int remainingSeconds = maxTurnSeconds;
  Timer? _turnTimer;

  @override
  void initState() {
    super.initState();
    _winPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startTurnTimer();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _winPulseController.dispose();
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

    if (widget.isVsBot && game.currentTurn == Disc.Yellow) {
      int botCol = game.getBestBotMove();
      if (botCol != -1) _dropInColumn(botCol);
    } else {
      setState(() {
        game.currentTurn = game.currentTurn == Disc.Red ? Disc.Yellow : Disc.Red;
      });
      _startTurnTimer();

      if (widget.isVsBot && game.currentTurn == Disc.Yellow) {
        _triggerBotMove();
      }
    }
  }

  void _dropInColumn(int col) {
    if (game.isGameOver) return;
    if (widget.isVsBot && game.currentTurn == Disc.Yellow) return;

    _executeDrop(col);
  }

  void _executeDrop(int col) {
    int row = game.dropDisc(col);
    if (row == -1) return; // ستون پر بود

    HapticFeedback.lightImpact();
    setState(() {});

    if (game.isGameOver) {
      _turnTimer?.cancel();
      _handleRoundEnd();
      return;
    }

    _startTurnTimer();

    if (widget.isVsBot && game.currentTurn == Disc.Yellow) {
      _triggerBotMove();
    }
  }

  void _triggerBotMove() {
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || game.isGameOver) return;
      int botCol = game.getBestBotMove();
      if (botCol != -1) {
        int r = game.dropDisc(botCol);
        if (r != -1) {
          HapticFeedback.lightImpact();
          setState(() {});
          if (game.isGameOver) {
            _turnTimer?.cancel();
            _handleRoundEnd();
          } else {
            _startTurnTimer();
          }
        }
      }
    });
  }

  void _handleRoundEnd() {
    HapticFeedback.heavyImpact();
    setState(() {
      if (game.winner == Disc.Red) redWins++;
      if (game.winner == Disc.Yellow) yellowWins++;
    });

    if (redWins >= targetWins || yellowWins >= targetWins) {
      Future.delayed(const Duration(milliseconds: 700), () {
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
      redWins = 0;
      yellowWins = 0;
      currentRound = 1;
      game.reset();
    });
    _startTurnTimer();
  }

  void _showMatchWinnerDialog() {
    final bool isRedWinner = redWins >= targetWins;
    final winnerTitle = isRedWinner
        ? 'بازیکن قرمز قهرمان شد! 🏆'
        : (widget.isVsBot ? 'ربات مسابقه را برد! 🤖' : 'بازیکن زرد قهرمان شد! 🏆');
    final accentColor = isRedWinner ? const Color(0xFFFF2A6D) : const Color(0xFFFFD600);

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
            winnerTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'نتیجه نهایی: $redWins بر $yellowWins',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 6),
            const Text('مسابقه ۳ رانده به پایان رسید.', style: TextStyle(color: Colors.white60, fontSize: 13)),
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
              _resetEntireMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          'اتصال چهار • راند $currentRound از ۳',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD600)),
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
            _buildVerticalBoard(),
            const Spacer(),
            if (game.isGameOver && redWins < targetWins && yellowWins < targetWins)
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerScore('قرمز', redWins, const Color(0xFFFF2A6D), game.currentTurn == Disc.Red),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildPlayerScore(
              widget.isVsBot ? 'ربات زرد' : 'زرد',
              yellowWins,
              const Color(0xFFFFD600),
              game.currentTurn == Disc.Yellow,
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
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimerAndTurnSection() {
    if (game.isGameOver) {
      final winnerText = game.isDraw
          ? 'این راند مساوی شد!'
          : (game.winner == Disc.Red
              ? 'برنده راند: بازیکن قرمز 🎯'
              : (widget.isVsBot ? 'برنده راند: ربات 🤖' : 'برنده راند: بازیکن زرد 🎯'));
      final color = game.winner == Disc.Red ? const Color(0xFFFF2A6D) : const Color(0xFFFFD600);
      return Text(winnerText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15));
    }

    final isRed = game.currentTurn == Disc.Red;
    final activeColor = isRed ? const Color(0xFFFF2A6D) : const Color(0xFFFFD600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: remainingSeconds / maxTurnSeconds,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isRed ? 'نوبت: بازیکن قرمز' : (widget.isVsBot ? 'ربات در حال تفکر...' : 'نوبت: بازیکن زرد'),
          style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  /// تخته ایستاده ۷ ستون در ۶ سطر
  Widget _buildVerticalBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF161E36), // رنگ بدنه تخته اتصال ۴
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(ConnectFourGame.cols, (colIndex) {
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _dropInColumn(colIndex),
                child: Column(
                  children: List.generate(ConnectFourGame.rows, (rowIndex) {
                    final disc = game.board[rowIndex][colIndex];
                    final isWinning = game.winningCells?.any(
                          (c) => c[0] == rowIndex && c[1] == colIndex,
                        ) ??
                        false;

                    return _buildHole(disc, isWinning);
                  }),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHole(Disc? disc, bool isWinning) {
    Color holeColor = const Color(0xFF0F111A); // رنگ خالی پس‌زمینه
    if (disc == Disc.Red) holeColor = const Color(0xFFFF2A6D);
    if (disc == Disc.Yellow) holeColor = const Color(0xFFFFD600);

    return AnimatedBuilder(
      animation: _winPulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(3.5),
          aspectRatio: 1.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: holeColor,
            border: Border.all(
              color: isWinning
                  ? Colors.greenAccent
                  : (disc != null ? Colors.white24 : Colors.black45),
              width: isWinning ? 2.5 : 1,
            ),
            boxShadow: isWinning
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.8),
                      blurRadius: 12 * _winPulseController.value,
                      spreadRadius: 2,
                    )
                  ]
                : (disc != null
                    ? [
                        BoxShadow(
                          color: holeColor.withOpacity(0.4),
                          blurRadius: 6,
                        )
                      ]
                    : []),
          ),
          child: isWinning
              ? const Center(
                  child: Icon(Icons.star_rounded, color: Colors.greenAccent, size: 18),
                )
              : null,
        );
      },
    );
  }

  Widget _buildNextRoundButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ElevatedButton(
        onPressed: _startNextRound,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD600),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('شروع راند بعدی ➔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHelperText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'روی هر ستون بزنید تا دیسک شما سقوط کند. ۴ دیسک در یک راستا = برد!',
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
  }
}
