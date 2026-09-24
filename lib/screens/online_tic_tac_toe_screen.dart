import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tic_tac_toe_model.dart';
import '../services/online_game_service.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

class OnlineTicTacToeScreen extends StatefulWidget {
  final String roomId;
  final String myRole; // 'X' or 'O'
  final String myPlayerName;
  final String opponentName;

  const OnlineTicTacToeScreen({
    super.key,
    required this.roomId,
    required this.myRole,
    required this.myPlayerName,
    required this.opponentName,
  });

  @override
  State<OnlineTicTacToeScreen> createState() => _OnlineTicTacToeScreenState();
}

class _OnlineTicTacToeScreenState extends State<OnlineTicTacToeScreen>
    with SingleTickerProviderStateMixin {
  final InfiniteTicTacToeGame game = InfiniteTicTacToeGame();
  final OnlineGameService _onlineService = OnlineGameService();
  late AnimationController _pulseController;
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  static const int targetWins = 2;
  int xWins = 0;
  int oWins = 0;
  int currentRound = 1;

  static const int maxTurnSeconds = 30;
  int remainingSeconds = maxTurnSeconds;
  Timer? _turnTimer;

  final List<ChatMessage> _messages = [];
  String? recentFloatingMessage;
  Timer? _floatingMessageTimer;

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
    _initNetworkSync();
  }

  /// اتصال به هماهنگ‌ساز ریل‌تایم بازی
  void _initNetworkSync() {
    _onlineService.listenToGameSync(
      roomId: widget.roomId,
      onOpponentMoved: (index, turn) {
        if (!mounted || isMyTurn) return;
        HapticFeedback.lightImpact();
        setState(() {
          game.makeMove(index);
        });
        if (game.isGameOver) {
          _turnTimer?.cancel();
          _handleRoundEnd();
        } else {
          _startTurnTimer();
        }
      },
      onChatReceived: (message) {
        if (!mounted) return;
        if (!message.startsWith('${widget.myPlayerName}:')) {
          setState(() {
            _messages.add(ChatMessage(text: message, isMe: false, time: DateTime.now()));
            recentFloatingMessage = message;
          });
          _floatingMessageTimer?.cancel();
          _floatingMessageTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) setState(() => recentFloatingMessage = null);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _floatingMessageTimer?.cancel();
    _pulseController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    _onlineService.cancelMatchmaking();
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
    if (!isMyTurn) return;

    _executeMove(index);
  }

  void _executeMove(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      game.makeMove(index);
    });

    // ارسال حرکت به سرور تا در گوشی حریف اعمال شود
    final nextRole = (widget.myRole == 'X') ? 'O' : 'X';
    _onlineService.pushMyMove(widget.roomId, index, nextRole);

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

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    final msgText = text.trim();
    final newMsg = ChatMessage(
      text: msgText,
      isMe: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(newMsg);
      recentFloatingMessage = '${widget.myPlayerName}: $msgText';
    });

    _onlineService.pushChatMessage(widget.roomId, msgText);

    _chatInputController.clear();
    _autoScrollChat();

    _floatingMessageTimer?.cancel();
    _floatingMessageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => recentFloatingMessage = null);
    });
  }

  void _autoScrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openLiveChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: const BoxDecoration(
                  color: Color(0xFF161926),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border(top: BorderSide(color: Colors.white12, width: 1.5)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: Color(0xFF00E5FF), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'گفتگو با ${widget.opponentName}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'هنوز پیامی ارسال نشده است.\nیک پیام برای حریف بنویسید!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              controller: _chatScrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                return Align(
                                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: msg.isMe ? const Color(0xFF00E5FF).withOpacity(0.2) : const Color(0xFF22273D),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: msg.isMe ? const Color(0xFF00E5FF).withOpacity(0.5) : Colors.white10,
                                      ),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10131E),
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'پیام خود را بنویسید...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E2235),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              onSubmitted: (value) {
                                _sendTextMessage(value);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF00E5FF)),
                            onPressed: () {
                              _sendTextMessage(_chatInputController.text);
                              setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            iWon ? 'شما برنده مسابقه شدید! 🏆' : '${widget.opponentName} برنده شد! 🥈',
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
          'مسابقه آنلاین (شما: ${widget.myRole})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent),
            tooltip: 'چت آنلاین',
            onPressed: _openLiveChatSheet,
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
            if (recentFloatingMessage != null) _buildFloatingChat(),
            const Spacer(),
            _buildBoard(),
            const Spacer(),
            if (game.isGameOver && xWins < targetWins && oWins < targetWins)
              _buildNextRoundButton()
            else
              _buildChatQuickBar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingChat() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_rounded, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              recentFloatingMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    final bool isMeX = widget.myRole == 'X';
    final String xName = isMeX ? '${widget.myPlayerName} (شما)' : widget.opponentName;
    final String oName = !isMeX ? '${widget.myPlayerName} (شما)' : widget.opponentName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF191D2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerScore(xName, 'X', xWins, const Color(0xFF00E5FF), game.currentTurn == Player.X),
            Container(width: 1, height: 44, color: Colors.white10),
            _buildPlayerScore(oName, 'O', oWins, const Color(0xFFFF2A6D), game.currentTurn == Player.O),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String name, String role, int wins, Color color, bool isActive) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color, width: 1),
              ),
              child: Text(
                role,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
          isMyTurn ? 'نوبت شماست! مهره را بچینید' : 'در انتظار حرکت حریف...',
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

  Widget _buildChatQuickBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: InkWell(
        onTap: _openLiveChatSheet,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'گفتگو با ${widget.opponentName}...',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
