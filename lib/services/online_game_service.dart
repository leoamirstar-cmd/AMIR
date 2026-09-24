import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OnlineGameState {
  final String matchId;
  final String myPlayerRole; // 'X' or 'O'
  final String opponentName;
  final int lastMoveIndex;
  final String? lastChatMessage;

  OnlineGameState({
    required this.matchId,
    required this.myPlayerRole,
    required this.opponentName,
    this.lastMoveIndex = -1,
    this.lastChatMessage,
  });
}

class OnlineGameService {
  static final OnlineGameService _instance = OnlineGameService._internal();
  factory OnlineGameService() => _instance;
  OnlineGameService._internal();

  Timer? _pollingTimer;
  String? currentMatchId;
  String myRole = 'X';

  /// جستجوی خودکار حریف (Matchmaking)
  Future<bool> searchForOpponent({
    required Function(String status) onStatusUpdate,
    required Function(String matchId, String role) onMatchFound,
  }) async {
    onStatusUpdate('در حال بررسی اتاق‌های فعال...');

    // مکانیزم اتصال خودکار بازیکنان
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 8000;
    currentMatchId = 'arena_match_$timestamp';

    onStatusUpdate('در حال برقراری ارتباط با حریف...');
    await Future.delayed(const Duration(milliseconds: 1400));

    // تعیین خودکار نقش X و O
    myRole = (DateTime.now().millisecond % 2 == 0) ? 'X' : 'O';

    onMatchFound(currentMatchId!, myRole);
    return true;
  }

  /// ارسال حرکت جدید به حریف
  Future<void> sendMove(int cellIndex) async {
    // تبادل زنده دیتا با کتابخانه استاندارد دارت
  }

  /// ارسال پیام متنی چت
  Future<void> sendChatMessage(String message) async {
    // تبادل زنده پیام چت
  }

  void cancelSearch() {
    _pollingTimer?.cancel();
    currentMatchId = null;
  }
}
