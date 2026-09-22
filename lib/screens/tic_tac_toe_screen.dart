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
  int xScore = 0;
  int oScore = 0;

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
      _handleWin();
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
            _handleWin();
          }
        }
      });
    }
  }

  void _handleWin() {
    HapticFeedback.heavyImpact();
    setState(() {
      if (game.winner == Player.X) xScore++;
      if (game.winner == Player.O) oScore++;
    });
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
          widget.isVsBot ? 'دوز بی‌نهایت (با ربات)' : 'دوز بی‌نهایت (دونفره)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: () => setState(() => game.reset()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildScoreBoard(),
            const SizedBox(height: 16),
            _buildTurnIndicator(),
            const Spacer(),
            _buildBoard(),
            const Spacer(),
            _buildHelperText(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
            _buildPlayerScore('بازیکن X', xScore, const Color(0xFF00E5FF), game.currentTurn == Player.X),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildPlayerScore(
              widget.isVsBot ? 'ربات O' : 'بازیکن O',
              oScore,
              const Color(0xFFFF2A6D),
              game.currentTurn == Player.O,
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
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    if (game.isGameOver) {
      final winnerName = game.winner == Player.X
          ? 'بازیکن X برنده شد! 🎉'
          : (widget.isVsBot ? 'ربات O برنده شد! 🤖' : 'بازیکن O برنده شد! 🎉');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: (game.winner == Player.X ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D)).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: game.winner == Player.X ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D),
          ),
        ),
        child: Text(
          winnerName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    final isX = game.currentTurn == Player.X;
    return Text(
      isX ? 'نوبت حرکت: بازیکن X' : (widget.isVsBot ? 'در حال فکر کردن ربات...' : 'نوبت حرکت: بازیکن O'),
      style: TextStyle(
        color: isX ? const Color(0xFF00E5FF) : const Color(0xFFFF2A6D),
        fontWeight: FontWeight.bold,
        fontSize: 15,
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

  Widget _buildHelperText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'قانون بی‌نهایت: هر بازیکن حداکثر ۳ مهره دارد. با گذاشتن مهره چهارم، قدیمی‌ترین مهره (چشمک‌زن) حذف می‌شود!',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
