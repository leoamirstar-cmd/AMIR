import 'package:flutter/material.dart';
import 'connect_four_screen.dart';

class ConnectFourLobbyScreen extends StatelessWidget {
  const ConnectFourLobbyScreen({super.key});

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
          'اتصال چهار (Connect 4)',
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
              // بنر گرافیکی قوانین بازی
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF2A6D).withOpacity(0.18),
                      const Color(0xFFFFD600).withOpacity(0.18),
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
                        Icon(Icons.circle, color: Color(0xFFFF2A6D), size: 36),
                        SizedBox(width: 8),
                        Icon(Icons.circle, color: Color(0xFFFFD600), size: 36),
                        SizedBox(width: 8),
                        Icon(Icons.circle, color: Color(0xFFFF2A6D), size: 36),
                        SizedBox(width: 8),
                        Icon(Icons.circle, color: Color(0xFFFFD600), size: 36),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'قانون اتصال ۴ مهره',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'دیسک‌ها را از بالا رها کنید! اولین کسی که ۴ دیسک پشت سر هم (افقی، عمودی یا مورب) بچیند برنده است.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              const Text(
                'حالت بازی را انتخاب کنید:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),

              // ۱. دو نفره آفلاین
              _buildLobbyCard(
                icon: Icons.people_alt_rounded,
                title: 'دونفره در یک گوشی (Pass & Play)',
                subtitle: 'رقابت دونفره هیجان‌انگیز با دوستت',
                color: const Color(0xFFFF2A6D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectFourScreen(isVsBot: false),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ۲. تک نفره با ربات
              _buildLobbyCard(
                icon: Icons.smart_toy_rounded,
                title: 'تک‌نفره با ربات هوشمند',
                subtitle: 'چالش در برابر هوش مصنوعی استراتژیک',
                color: const Color(0xFFFFD600),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectFourScreen(isVsBot: true),
                    ),
                  );
                },
              ),

              const Spacer(),

              // جایگاه بنر تپسل
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
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
