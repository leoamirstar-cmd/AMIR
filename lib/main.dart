import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/tic_tac_toe_screen.dart';

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

  void _showModeSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF161926),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'انتخاب حالت بازی',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildModeOption(
              context: context,
              icon: Icons.people_alt_rounded,
              title: 'دونفره آفلاین (Pass & Play)',
              subtitle: 'بازی با دوستت روی همین گوشی',
              color: const Color(0xFF00E5FF),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfiniteTicTacToeScreen(isVsBot: false),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              context: context,
              icon: Icons.smart_toy_rounded,
              title: 'تک‌نفره با ربات هوشمند',
              subtitle: 'هوش مصنوعی تاکتیکی و هوشمند',
              color: const Color(0xFFFF2A6D),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfiniteTicTacToeScreen(isVsBot: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2438),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

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
              // هدر لوگوی اپلیکیشن
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sports_esports_rounded, color: Colors.cyanAccent, size: 28),
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

              // کارت فعال بازی ۱: دوز بی‌نهایت
              _buildGameCard(
                title: 'دوز بی‌نهایت',
                englishTitle: 'Infinite Tic-Tac-Toe',
                description: 'هر بازیکن ۳ مهره؛ بازی بدون تساوی با استراتژی پیوسته!',
                accentColor: const Color(0xFF00E5FF),
                icon: Icons.grid_3x3_rounded,
                isLocked: false,
                onTap: () => _showModeSelectionDialog(context),
              ),

              const SizedBox(height: 14),

              // کارت قفل‌شده بازی ۲: اتصال ۴
              _buildGameCard(
                title: 'اتصال چهار (Connect 4)',
                englishTitle: 'به زودی در آپدیت بعدی',
                description: '۴ مهره هم‌رنگ را در یک خط افقی، عمودی یا مورب بچینید.',
                accentColor: const Color(0xFFFF2A6D),
                icon: Icons.blur_linear_rounded,
                isLocked: true,
                onTap: () {},
              ),

              const SizedBox(height: 14),

              // کارت قفل‌شده بازی ۳: نقطه‌ها و خط‌ها
              _buildGameCard(
                title: 'نقطه‌خط (Dots & Boxes)',
                englishTitle: 'به زودی در آپدیت بعدی',
                description: 'بستن اضلاع مربع و فتح بیشترین قلمرو.',
                accentColor: const Color(0xFFFFB800),
                icon: Icons.border_all_rounded,
                isLocked: true,
                onTap: () {},
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
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF151824),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLocked ? Colors.white.withOpacity(0.06) : accentColor.withOpacity(0.4),
            width: isLocked ? 1 : 1.5,
          ),
          boxShadow: isLocked
              ? []
              : [
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
                color: isLocked ? Colors.white10 : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.white30 : accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isLocked ? Colors.white54 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    englishTitle,
                    style: TextStyle(
                      color: isLocked ? Colors.white30 : accentColor.withOpacity(0.85),
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
            Icon(
              Icons.chevron_left_rounded,
              color: isLocked ? Colors.white24 : Colors.white70,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
