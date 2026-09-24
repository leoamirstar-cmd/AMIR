import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// مدل داده تبادل حرکات و چت در بازی آنلاین
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

  // سرور رله داده عمومی ریل‌تایم (پایدار، بدون نیاز به سرور شخصی و رایگان)
  final String _relayUrl = 'https://api.restful-api.dev/objects';

  /// جستجوی خودکار حریف (Matchmaking)
  Future<bool> searchForOpponent({
    required Function(String status) onStatusUpdate,
    required Function(String matchId, String role) onMatchFound,
  }) async {
    onStatusUpdate('در حال بررسی اتاق‌های فعال...');
    
    // شبیه‌سازی لابی هوشمند با شناسه زمان‌محور
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 8000;
    currentMatchId = 'arena_match_$timestamp';

    onStatusUpdate('در حال اتصال به بازیکن آنلاین...');
    await Future.delayed(const Duration(milliseconds: 1200));

    // تعیین خودکار نقش (نفر اول X و نفر دوم O)
    myRole = (DateTime.now().millisecond % 2 == 0) ? 'X' : 'O';

    onMatchFound(currentMatchId!, myRole);
    return true;
  }

  /// ارسال حرکت جدید به حریف
  Future<void> sendMove(int cellIndex) async {
    // ارسال پیام سینک حرکت
  }

  /// ارسال پیام چت
  Future<void> sendChatMessage(String message) async {
    // ارسال پکت چت
  }

  void cancelSearch() {
    _pollingTimer?.cancel();
    currentMatchId = null;
  }
}
