import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/notification_inbox_service.dart';
import '../theme/app_theme.dart';
import 'admin/admin_screen.dart';
import 'games/games_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/my_bookings_screen.dart';
import 'profile/profile_screen.dart';
import 'venue/my_venue_screen.dart';
import 'venue/venue_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _playerScreens = const [
    HomeScreen(),
    GamesScreen(),
    MyBookingsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  late final List<Widget> _venueScreens = const [
    MyVenueScreen(),
    VenueDashboardScreen(),
    ProfileScreen(),
  ];

  late final List<Widget> _adminScreens = const [
    HomeScreen(),
    GamesScreen(),
    AdminScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null && user.isVenue) {
      _currentIndex = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch — rebuilds when auth state changes (e.g. logout)
    final user = context.watch<AuthService>().currentUser;
    if (user != null && user.isVenue) return _buildVenueLayout();
    if (user != null && user.isAdmin) return _buildAdminLayout();
    return _buildPlayerLayout();
  }

  Widget _borderedNav(NavigationBar nav) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.borderColor, width: 0.5),
          ),
        ),
        child: nav,
      );

  // ── PLAYER ──────────────────────────────────────────────
  Widget _buildPlayerLayout() {
    final l = AppLocalizations.of(context);
    final screens = _playerScreens;
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);
    final unread = context.watch<NotificationInboxService>().unreadCount;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: _borderedNav(
        NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.stadium_outlined),
              selectedIcon: const Icon(Icons.stadium),
              label: l.tabVenues,
            ),
            NavigationDestination(
              icon: const Icon(Icons.sports_soccer_outlined),
              selectedIcon: const Icon(Icons.sports_soccer),
              label: l.tabGames,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_outline),
              selectedIcon: const Icon(Icons.bookmark),
              label: l.tabBookings,
            ),
            NavigationDestination(
              icon: unread > 0
                  ? Badge(
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: l.tabNotifications,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l.tabProfile,
            ),
          ],
        ),
      ),
    );
  }

  // ── VENUE OWNER ─────────────────────────────────────────
  Widget _buildVenueLayout() {
    final l = AppLocalizations.of(context);
    final screens = _venueScreens;
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: _borderedNav(
        NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.stadium_outlined),
              selectedIcon: const Icon(Icons.stadium),
              label: l.tabMyVenue,
            ),
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: l.tabDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l.tabProfile,
            ),
          ],
        ),
      ),
    );
  }

  // ── ADMIN ────────────────────────────────────────────────
  Widget _buildAdminLayout() {
    final l = AppLocalizations.of(context);
    final screens = _adminScreens;
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: _borderedNav(
        NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.stadium_outlined),
              selectedIcon: const Icon(Icons.stadium),
              label: l.tabVenues,
            ),
            NavigationDestination(
              icon: const Icon(Icons.sports_soccer_outlined),
              selectedIcon: const Icon(Icons.sports_soccer),
              label: l.tabGames,
            ),
            NavigationDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: const Icon(Icons.admin_panel_settings),
              label: l.tabAdmin,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}
