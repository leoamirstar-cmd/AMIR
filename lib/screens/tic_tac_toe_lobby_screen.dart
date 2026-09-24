import 'package:flutter/material.dart';
import 'tic_tac_toe_screen.dart';
import 'online_tic_tac_toe_screen.dart';
import '../services/online_game_service.dart';

class TicTacToeLobbyScreen extends StatefulWidget {
  const TicTacToeLobbyScreen({super.key});

  @override
  State<TicTacToeLobbyScreen> createState() => _TicTacToeLobbyScreenState();
}

class _TicTacToeLobbyScreenState extends State<TicTacToeLobbyScreen> {
  final OnlineGameService _onlineService = OnlineGameService();

  void _startQuickMatchmaking(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String currentStatus = 'در حال اسکن بازیکنان آماده...';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            // شروع جستجو
            _onlineService.searchForOpponent(
              onStatusUpdate: (status) {
                setDialogState(() {
                  currentStatus = status;
                });
              },
              onMatchFound: (matchId, role) {
                Navigator.pop(dialogCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnlineTicTacToeScreen(
                      matchId: matchId,
                      myRole: role,
                    ),
                  ),
                );
              },
            );

            return AlertDialog(
              backgroundColor: const Color(0xFF161926),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFFFB800), width: 1.5),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB800)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'جستجوی حریف آنلاین',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      _onlineService.cancelSearch();
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('انصراف', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'دوز بی‌نهایت',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.15),
                      const Color(0xFFFF2A6D).withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, color: Color(0xFF00E5FF), size: 48),
                        SizedBox(width: 16),
                        Icon(Icons.circle_outlined, color: Color(0xFFFF2A6D), size: 42),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'قانون ۳ مهره بی‌پایان',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'بازی بدون تساوی! قدیمی‌ترین مهره با کاشت مهره چهارم حذف می‌شود.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'حالت بازی را انتخاب کنید:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),

              // گزینه ۱: دونفره آفلاین
              _buildLobbyCard(
                icon: Icons.people_alt_rounded,
                title: 'دونفره آفلاین (Pass & Play)',
                subtitle: 'رقابت دونفره روی همین صفحه گوشی',
                color: const Color(0xFF00E5FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InfiniteTicTacToeScreen(isVsBot: false),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // گزینه ۲: تک‌نفره با ربات
              _buildLobbyCard(
                icon: Icons.smart_toy_rounded,
                title: 'تک‌نفره با ربات هوشمند',
                subtitle: 'رقابت تاکتیکی در برابر هوش مصنوعی',
                color: const Color(0xFFFF2A6D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InfiniteTicTacToeScreen(isVsBot: true),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // گزینه ۳: آنلاین خودکار (فعال شده)
              _buildLobbyCard(
                icon: Icons.wifi_rounded,
                title: 'بازی آنلاین زنده (Matchmaking)',
                subtitle: 'جستجوی خودکار حریف و چت حین بازی',
                color: const Color(0xFFFFB800),
                onTap: () => _startQuickMatchmaking(context),
              ),

              const Spacer(),
              Container(
                height: 55,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Center(
                  child: Text(
                    'جایگاه بنر استاندارد تپسل',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161926),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}
