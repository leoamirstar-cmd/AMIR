import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tic_tac_toe_model.dart';
import '../services/online_game_service.dart';

class OnlineTicTacToeScreen extends StatefulWidget {
  final String matchId;
  final String myRole; // 'X' or 'O'

  const OnlineTicTacToeScreen({
    super.key,
    required this.matchId,
    required this.myRole,
  });

  @override
  State<OnlineTicTacToeScreen> createState() => _OnlineTicTacToeScreenState();
}

class _OnlineTicTacToeScreenState extends State<OnlineTicTacToeScreen>
    with SingleTickerProviderStateMixin {
  final InfiniteTicTacToeGame game = InfiniteTicTacToeGame();
  late AnimationController _pulseController;

  static const int targetWins = 2;
  int xWins = 0;
  int oWins = 0;
  int currentRound = 1;

  static const int maxTurnSeconds = 30;
  int remainingSeconds = maxTurnSeconds;
  Timer? _turnTimer;

  String? recentChatMessage;
  Timer? _chatDismissTimer;

  bool get isMyTurn =>
      (widget.myRole == 'X' && game.currentTurn == Player.X) ||
      (widget.myRole == 'O' && game.currentTurn == Player.O);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startTurnTimer();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _chatDismissTimer?.cancel();
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
        } else {
          _handleTimeOut();
        }
      });
    });
  }

  void _handleTimeOut() {
    if (game.isGameOver) return;
    setState(() {
      game.currentTurn = game.currentTurn == Player.X ? Player.O : Player.X;
    });
    _startTurnTimer();
  }

  void _onCellTapped(int index) {
    if (game.isGameOver || game.board[index] != null) return;
    if (!isMyTurn) return; // در صورت نوبت حریف، لمس غیرفعال است

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

    _startTurnTimer();
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

  void _showChatBottomSheet() {
    final List<String> quickMessages = [
      'سلام! آماده‌ای؟ 👋',
      'عجب حرکتی زدی! 👏',
      'فکرشم نمی‌کردم! 🤯',
      'کمی سریع‌تر لطفاً ⏳',
      'دست‌خوش! بازی قشنگی بود 🔥',
      'یک راند دیگه؟ 🔄',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF161926),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'ارسال پیام سریع به حریف',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: quickMessages.map((msg) {
                return ActionChip(
                  backgroundColor: const Color(0xFF22273D),
                  label: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _broadcastChatMessage(msg);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _broadcastChatMessage(String message) {
    setState(() {
      recentChatMessage = message;
    });

    _chatDismissTimer?.cancel();
    _chatDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          recentChatMessage = null;
        });
      }
    });
  }

  void _showMatchWinnerDialog() {
    final bool isXWinner = xWins >= targetWins;
    final bool iWon = (isXWinner && widget.myRole == 'X') || (!isXWinner && widget.myRole == 'O');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161926),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: iWon ? Colors.cyanAccent : Colors.redAccent, width: 1.5),
        ),
        title: Center(
          child: Text(
            iWon ? 'شما برنده مسابقه شدید! 🏆' : 'حریف مسابقه را برد! 🥈',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Text(
          'نتیجه نهایی: $xWins بر $oWins',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: iWon ? Colors.cyanAccent : Colors.redAccent,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: iWon ? Colors.cyanAccent : Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('خروج به لابی', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
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
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'مسابقه آنلاین (نقش شما: ${widget.myRole})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            tooltip: 'چت زنده',
            onPressed: _showChatBottomSheet,
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
            if (recentChatMessage != null) _buildChatOverlay(),
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

  Widget _buildChatOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_rounded, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 8),
          Text(
            recentChatMessage!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    final isMyTurnX = widget.myRole == 'X';
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
            _buildPlayerScore(isMyTurnX ? 'شما (X)' : 'حریف (X)', xWins, const Color(0xFF00E5FF), game.currentTurn == Player.X),
            Container(width: 1, height: 40, color: Colors.white10),
            _buildPlayerScore(!isMyTurnX ? 'شما (O)' : 'حریف (O)', oWins, const Color(0xFFFF2A6D), game.currentTurn == Player.O),
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
      final winnerName = game.winner == Player.X ? 'برنده راند: X 🎯' : 'برنده راند: O 🎯';
      return Text(
        winnerName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
      );
    }

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
            valueColor: AlwaysStoppedAnimation<Color>(
              isMyTurn ? const Color(0xFF00E5FF) : Colors.white38,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isMyTurn ? 'نوبت شماست! یک مهره انتخاب کنید' : 'در انتظار حرکت حریف...',
          style: TextStyle(
            color: isMyTurn ? const Color(0xFF00E5FF) : Colors.white60,
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
          double opacity = 1.0;
          double scale = 1.0;

          if (isFading && !game.isGameOver) {
            opacity = 0.4 + (_pulseController.value * 0.6);
            scale = 0.90 + (_pulseController.value * 0.15);
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
    return Icon(Icons.close_rounded, size: 58, color: color);
  }

  Widget _buildOIcon(bool isWinning, bool isFading) {
    final color = isFading ? Colors.orangeAccent : const Color(0xFFFF2A6D);
    return Icon(Icons.circle_outlined, size: 50, color: color);
  }

  Widget _buildNextRoundButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ElevatedButton(
        onPressed: _startNextRound,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
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
        'مسابقه آنلاین زنده • با آیکون چت بالا پیام بفرستید',
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
    );
  }
}
