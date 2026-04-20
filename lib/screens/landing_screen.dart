import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/main_screen.dart';
import '../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _sports = [
    _Sport(
      name: 'Football',
      icon: Icons.sports_soccer_rounded,
      available: true,
    ),
    _Sport(
      name: 'Basketball',
      icon: Icons.sports_basketball_rounded,
      available: false,
    ),
    _Sport(
      name: 'Padel',
      icon: Icons.sports_tennis_rounded,
      available: false,
    ),
    _Sport(
      name: 'Tennis',
      icon: Icons.sports_tennis_rounded,
      available: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Header
              Text(
                'PlayNow',
                style: context.tt.titleLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                l.findYourGame,
                style: TextStyle(
                  color:    context.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 36),

              // Sport grid
              Expanded(
                child: GridView.count(
                  crossAxisCount:  2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing:  12,
                  childAspectRatio: 0.9,
                  children: _sports
                      .map((s) => _SportCard(
                            sport: s,
                            onTap: () => _onSportTap(context, s),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _onSportTap(BuildContext context, _Sport sport) {
    if (sport.available) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const MainScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sport.name} is coming soon!'),
        ),
      );
    }
  }
}

class _SportCard extends StatelessWidget {
  final _Sport sport;
  final VoidCallback onTap;

  const _SportCard({required this.sport, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = sport.available;
    final bgColor  = isAvailable ? context.greenTint  : context.surface;
    final border   = isAvailable ? context.greenBorder : context.borderColor;
    final iconColor = isAvailable ? context.primary    : context.textHint;
    final textColor = isAvailable ? context.primary    : context.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isAvailable
                    ? context.primary.withOpacity(0.12)
                    : context.borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(sport.icon, color: iconColor, size: 26),
            ),

            const Spacer(),

            Text(
              sport.name,
              style: TextStyle(
                color:      textColor,
                fontSize:   16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAvailable
                    ? context.primary.withOpacity(0.1)
                    : context.borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAvailable
                    ? AppLocalizations.of(context).active
                    : AppLocalizations.of(context).inactive,
                style: TextStyle(
                  color:      isAvailable ? context.primary : context.textHint,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sport {
  final String name;
  final IconData icon;
  final bool available;

  const _Sport({
    required this.name,
    required this.icon,
    required this.available,
  });
}
