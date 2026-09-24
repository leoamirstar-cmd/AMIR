import 'dart:async';
import 'dart:convert';
import 'dart:io';

class OnlineGameService {
  static final OnlineGameService _instance = OnlineGameService._internal();
  factory OnlineGameService() => _instance;
  OnlineGameService._internal();

  Timer? _searchTimer;
  Timer? _gameSyncTimer;

  String? activeRoomId;
  String myPlayerName = 'بازیکن';
  String myRole = 'X'; // X یا O
  String opponentName = 'در انتظار حریف...';

  // سرور داده عمومی و بدون تحریم با تاخیر کم
  final String _endpoint = 'https://api.restful-api.dev/objects';

  /// جستجوی واقعی دوطرفه
  void searchRealOpponent({
    required String name,
    required Function(String status) onStatusUpdate,
    required Function(String myRole, String opponentName, String roomId) onMatchFound,
  }) {
    myPlayerName = name.trim().isEmpty ? 'بازیکن' : name.trim();
    onStatusUpdate('در حال جستجوی بازیکن آنلاین...');

    int attempts = 0;
    _searchTimer?.cancel();

    // هر ۲ ثانیه سرور را بررسی می‌کند
    _searchTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);

        // ۱. بررسی آیا اتاقی منتظر بازیکن است؟
        final request = await client.getUrl(Uri.parse('$_endpoint?page=1&limit=5'));
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final List dynamicList = jsonDecode(responseBody);

          // جستجوی اتاق بازی دوز با وضعیت منتظر (waiting)
          Map<String, dynamic>? availableRoom;
          for (var item in dynamicList) {
            if (item['data'] != null &&
                item['data']['game'] == 'duo_infinite_ttt' &&
                item['data']['status'] == 'waiting' &&
                item['data']['host'] != myPlayerName) {
              availableRoom = item;
              break;
            }
          }

          if (availableRoom != null) {
            // اتاق پیدا شد! ما به عنوان بازیکن دوم (O) وارد می‌شویم
            _searchTimer?.cancel();
            activeRoomId = availableRoom['id'];
            myRole = 'O';
            opponentName = availableRoom['data']['host'] ?? 'حریف';

            onStatusUpdate('حریف پیدا شد! در حال پیوستن به بازی...');
            await _joinRoom(activeRoomId!, myPlayerName);
            onMatchFound(myRole, opponentName, activeRoomId!);
            return;
          }
        }

        // اگر تا ۳ ثانیه اتاقی نبود، خودمان میزبان می‌شویم و اتاق جدید می‌سازیم
        if (activeRoomId == null && attempts >= 2) {
          onStatusUpdate('شما میزبان شدید. در انتظار پیوستن بازیکن دوم...');
          activeRoomId = await _createRoom(myPlayerName);
          myRole = 'X';
        }

        // اگر خودمان میزبان شدیم، مرتب بررسی می‌کنیم آیا نفر دوم اضافه شد یا خیر
        if (activeRoomId != null && myRole == 'X') {
          final checkReq = await client.getUrl(Uri.parse('$_endpoint/$activeRoomId'));
          final checkRes = await checkReq.close();
          if (checkRes.statusCode == 200) {
            final body = await checkRes.transform(utf8.decoder).join();
            final roomData = jsonDecode(body);
            if (roomData['data'] != null && roomData['data']['guest'] != null) {
              // نفر دوم پیوست!
              _searchTimer?.cancel();
              opponentName = roomData['data']['guest'];
              onStatusUpdate('بازیکن متصل شد! شروع بازی...');
              onMatchFound(myRole, opponentName, activeRoomId!);
              return;
            }
          }
        }
      } catch (e) {
        onStatusUpdate('بررسی اتصال به اینترنت...');
      }

      if (attempts >= 45) { // بعد از ۹۰ ثانیه در صورت نیافتن حریف
        _searchTimer?.cancel();
        onStatusUpdate('بازیکنی یافت نشد. لطفاً بعداً تلاش کنید.');
      }
    });
  }

  Future<String?> _createRoom(String host) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers.set('Content-Type', 'application/json');
      final payload = jsonEncode({
        "name": "Duo TicTacToe Match",
        "data": {
          "game": "duo_infinite_ttt",
          "host": host,
          "guest": null,
          "status": "waiting",
          "currentTurn": "X",
          "lastMove": -1,
          "chat": null
        }
      });
      request.write(payload);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final res = jsonDecode(body);
        return res['id'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _joinRoom(String roomId, String guest) async {
    try {
      final client = HttpClient();
      final request = await client.putUrl(Uri.parse('$_endpoint/$roomId'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        "name": "Duo TicTacToe Match",
        "data": {
          "game": "duo_infinite_ttt",
          "host": opponentName,
          "guest": guest,
          "status": "playing",
          "currentTurn": "X",
          "lastMove": -1,
          "chat": null
        }
      }));
      await request.close();
    } catch (_) {}
  }

  /// هماهنگ‌سازی لحظه‌ای حرکت‌ها و چت در حین بازی
  void listenToGameSync({
    required String roomId,
    required Function(int moveIndex, String turn) onOpponentMoved,
    required Function(String message) onChatReceived,
  }) {
    _gameSyncTimer?.cancel();
    int lastSeenMove = -1;
    String? lastSeenChat;

    _gameSyncTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse('$_endpoint/$roomId'));
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body)['data'];
          if (data != null) {
            final int move = data['lastMove'] ?? -1;
            final String turn = data['currentTurn'] ?? 'X';
            final String? chat = data['chat'];

            if (move != -1 && move != lastSeenMove) {
              lastSeenMove = move;
              onOpponentMoved(move, turn);
            }

            if (chat != null && chat != lastSeenChat) {
              lastSeenChat = chat;
              onChatReceived(chat);
            }
          }
        }
      } catch (_) {}
    });
  }

  /// ارسال حرکت شما به سرور تا در گوشی حریف اعمال شود
  Future<void> pushMyMove(String roomId, int moveIndex, String nextTurn) async {
    try {
      final client = HttpClient();
      final request = await client.putUrl(Uri.parse('$_endpoint/$roomId'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        "name": "Duo TicTacToe Match",
        "data": {
          "game": "duo_infinite_ttt",
          "status": "playing",
          "lastMove": moveIndex,
          "currentTurn": nextTurn,
        }
      }));
      await request.close();
    } catch (_) {}
  }

  /// ارسال پیام چت به سرور
  Future<void> pushChatMessage(String roomId, String message) async {
    try {
      final client = HttpClient();
      final request = await client.putUrl(Uri.parse('$_endpoint/$roomId'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        "name": "Duo TicTacToe Match",
        "data": {
          "chat": "$myPlayerName: $message",
        }
      }));
      await request.close();
    } catch (_) {}
  }

  void cancelMatchmaking() {
    _searchTimer?.cancel();
    _gameSyncTimer?.cancel();
    activeRoomId = null;
  }
}
