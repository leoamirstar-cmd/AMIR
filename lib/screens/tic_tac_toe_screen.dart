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
  late AnimationController _fadePulseController;

  static const int targetWins = 2; // سیستم ۲ برد از ۳ راند (Best of 3)
  int xWins = 0;
  int oWins = 0;
  int currentRound = 1;

  @override
  void initState() {
    super.initState();
    _fadePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadePulseController.dispose();
    super.dispose();
  }

  void _onCellTapped(int index) {
    if (game.isGameOver || game.board[index] != null) return;
    if (widget.isVsBot && game.currentTurn == Player.O) return;

    HapticFeedback.lightImpact();
    setState(() {
      game.makeMove(index);
    });

    if (game.isGameOver) {
      _handleRoundEnd();
      return;
    }

    if (widget.isVsBot && game.currentTurn == Player.O) {
      Future.delayed(const Duration(milliseconds: 550), () {
        if (!mounted || game.isGameOver) return;
        int botMove = game.getBestBotMove();
        if (botMove != -1) {
          HapticFeedback.lightImpact();
          setState(() {
            game.makeMove(botMove);
          });
          if (game.isGameOver) {
            _handleRoundEnd();
          }
        }
      });
    }
  }

  void _handleRoundEnd() {
    HapticFeedback.heavyImpact();
    setState(() {
      if (game.winner == Player.X) xWins++;
      if (game.winner == Player.O) oWins++;
    });

    // بررسی برد کل مسابقه (رسیدن به ۲ برد)
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
  }

  void _resetEntireMatch() {
    setState(() {
      xWins = 0;
      oWins = 0;
      currentRound = 1;
      game.reset();
    });
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
              Navigator.pop(context); // بازگشت به لابی
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
            const SizedBox(height: 8),
            _buildScoreBoard(),
            const SizedBox(height: 14),
            _buildTurnOrStatusBanner(),
            const Spacer(),
            _buildBoard(),
            const Spacer(),
            if (game.isGameOver && xWins < targetWins && oWins < targetWins)
              _buildNextRoundButton()
            else
              _buildHelperText(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
            Container(width: 1, height: 44, color: Colors.white10),
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
        const SizedBox(height: 8),
        // چراغ‌های پیروزی در راندها (۲ راند برای برد)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(targetWins, (index) {
            final isAchieved = index < wins;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 14,
              height: 14,
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

  Widget _buildTurnOrStatusBanner() {
    if (game.isGameOver) {
      final winnerName = game.winner == Player.X
          ? 'برنده راند: بازیکن X 🎯'
          : (widget.isVsBot ? 'برنده راند: ربات O 🤖' : 'برنده راند: بازیکن O 🎯');
      final color = game.winner == Player.X ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
    return Text(
      isX ? 'نوبت حرکت: بازیکن X' : (widget.isVsBot ? 'ربات در حال انتخاب حرکت...' : 'نوبت حرکت: بازیکن O'),
      style: TextStyle(
        color: isX ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
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
        animation: _fadePulseController,
        builder: (context, child) {
          double opacity = 1.0;
          if (isFading && !game.isGameOver) {
            opacity = 0.35 + (_fadePulseController.value * 0.55);
          }

          return Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWinningCell
                      ? Colors.amberAccent
                      : (isFading
                          ? Colors.orangeAccent.withOpacity(0.8)
                          : Colors.white.withOpacity(0.05)),
                  width: isWinningCell ? 3 : (isFading ? 2 : 1),
                ),
                boxShadow: isWinningCell
                    ? [
                        BoxShadow(
                          color: Colors.amberAccent.withOpacity(0.5),
                          blurRadius: 15,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: player == null
                    ? null
                    : (player == Player.X
                        ? _buildXIcon(isWinningCell)
                        : _buildOIcon(isWinningCell)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildXIcon(bool isWinning) {
    return Icon(
      Icons.close_rounded,
      size: 58,
      color: const Color(0xFF00E5FF),
      shadows: [
        Shadow(
          color: const Color(0xFF00E5FF).withOpacity(isWinning ? 1.0 : 0.6),
          blurRadius: isWinning ? 25 : 12,
        ),
      ],
    );
  }

  Widget _buildOIcon(bool isWinning) {
    return Icon(
      Icons.circle_outlined,
      size: 50,
      color: const Color(0xFFFF2A6D),
      shadows: [
        Shadow(
          color: const Color(0xFFFF2A6D).withOpacity(isWinning ? 1.0 : 0.6),
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
            Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'هر بازیکن حداکثر ۳ مهره دارد. قدیمی‌ترین مهره (چشمک‌زن) با حرکت جدید پاک می‌شود!',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
