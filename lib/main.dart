import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/tic_tac_toe_lobby_screen.dart';
import 'screens/connect_four_lobby_screen.dart';
import 'screens/dots_and_boxes_lobby_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const DuoArenaApp());
}

class DuoArenaApp extends StatelessWidget {
  const DuoArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duo Arena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0C14),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.cyanAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DUO ARENA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'مجموعه بازی‌های دونفره',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'بازی‌های موجود',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // ۱. دوز بی‌نهایت
              _buildGameCard(
                title: 'دوز بی‌نهایت',
                englishTitle: 'Infinite Tic-Tac-Toe',
                description: 'هر بازیکن ۳ مهره؛ بازی بدون تساوی با استراتژی پیوسته!',
                accentColor: const Color(0xFF00E5FF),
                icon: Icons.grid_3x3_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TicTacToeLobbyScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ۲. اتصال چهار
              _buildGameCard(
                title: 'اتصال چهار (Connect 4)',
                englishTitle: 'Connect 4 Strategy',
                description: '۴ مهره هم‌رنگ را در یک خط افقی، عمودی یا مورب بچینید.',
                accentColor: const Color(0xFFFF2A6D),
                icon: Icons.blur_linear_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectFourLobbyScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ۳. نقطه‌خط بزرگ
              _buildGameCard(
                title: 'نقطه‌خط (Dots & Boxes)',
                englishTitle: 'Dots & Territory Arena',
                description: 'زمین بزرگ ۴۹ مربعی؛ خط بکشید و مربع‌ها را فتح کنید!',
                accentColor: const Color(0xFFFFB800),
                icon: Icons.border_all_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DotsAndBoxesLobbyScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // بنر استاندارد تپسل
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

  Widget _buildGameCard({
    required String title,
    required String englishTitle,
    required String description,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF151824),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    englishTitle,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
