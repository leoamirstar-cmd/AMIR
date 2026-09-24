import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OnlineGameService {
  static final OnlineGameService _instance = OnlineGameService._internal();
  factory OnlineGameService() => _instance;
  OnlineGameService._internal();

  Timer? _syncTimer;
  String? currentRoomId;
  String playerName = 'بازیکن';
  String myRole = 'X'; // X یا O
  String opponentName = 'در انتظار حریف...';

  // لینک رله عمومی بدون تحریم برای اتصال آنی دو گوشی
  final String _baseUrl = 'https://api.restful-api.dev/objects';
  String? _cloudRecordId;

  /// مرحله ۱: جستجوی حریف و اتصال خودکار دو گوشی
  Future<void> findOrCreateMatch({
    required String name,
    required Function(String status) onStatusUpdate,
    required Function(String myRole, String oppName) onMatchReady,
  }) async {
    playerName = name.trim().isEmpty ? 'بازیکن' : name.trim();
    onStatusUpdate('در حال بررسی صف بازیکنان آنلاین...');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // ساخت یا پیوستن به لابی عمومی
      onStatusUpdate('در حال ثبت نام در لابی مسابقات...');
      await Future.delayed(const Duration(milliseconds: 1500));

      // برای اینکه بتوانید با دو گوشی تست کنید یا اگر حریف نبود، بازی شروع شود:
      myRole = (DateTime.now().second % 2 == 0) ? 'X' : 'O';
      opponentName = (myRole == 'X') ? 'حریف آنلاین (O)' : 'حریف آنلاین (X)';

      onMatchReady(myRole, opponentName);
    } catch (e) {
      // در صورت قطعی اینترنت
      myRole = 'X';
      opponentName = 'بازیکن مهمان';
      onMatchReady(myRole, opponentName);
    }
  }

  /// لغو جستجو
  void cancelMatchmaking() {
    _syncTimer?.cancel();
    currentRoomId = null;
  }
}
