import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/match_booking_service.dart';
import 'services/friend_service.dart';
import 'services/notification_inbox_service.dart';
import 'services/notification_service.dart';
import 'services/rating_service.dart';
import 'services/session_service.dart';
import 'services/media_service.dart';
import 'services/theme_service.dart';
import 'services/venue_service.dart';
final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => NotificationInboxService()),
        Provider(create: (_) => VenueService()),
        Provider(create: (_) => SessionService()),
        Provider(create: (_) => DashboardService()),
        Provider(create: (_) => MatchBookingService()),
        Provider(create: (_) => RatingService()),
        ChangeNotifierProvider(create: (_) => FriendService()),
        ChangeNotifierProvider(create: (_) => MediaService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const PlayNowApp(),
    ),
  );
}
class PlayNowApp extends StatefulWidget {
  const PlayNowApp({super.key});
  @override
  State<PlayNowApp> createState() => _PlayNowAppState();
}
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
class _PlayNowAppState extends State<PlayNowApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) NotificationService.initialize();
  }
  @override
  Widget build(BuildContext context) {
    final locale    = context.watch<LocaleProvider>().locale;
    final themeMode = context.watch<ThemeService>().mode;
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: NotificationService.messengerKey,
      title: 'PlayNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isInitializing) return const _SplashScreen();
          if (!auth.isLoggedIn) return const LoginScreen();
          return const LandingScreen();
        },
      ),
    );
  }
}
