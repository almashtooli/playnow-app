import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    _fcm.onTokenRefresh.listen((_) => saveFcmToken());
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type'] as String? ?? '';
      final isAr = _currentLocaleIsAr();

      // Translate the title using the notification type when possible.
      final translatedTitle = _translateType(type, isAr);
      final title = translatedTitle.isNotEmpty
          ? translatedTitle
          : (message.notification?.title ?? '');
      final body = message.notification?.body ?? '';

      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  static Future<void> saveFcmToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) {
        await apiClient.post('/notifications/token', body: {'token': token});
        debugPrint('FCM token saved!');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  // ── Locale helpers ─────────────────────────────────────────────────────────

  // Check the stored locale synchronously from an in-memory cache set on
  // locale change. Falls back to English if unavailable.
  static bool _isArCached = false;

  static bool _currentLocaleIsAr() => _isArCached;

  /// Call this whenever the locale changes (from LocaleProvider).
  static void setLocaleAr(bool isAr) => _isArCached = isAr;

  // ── Type → translated title ────────────────────────────────────────────────

  static String _translateType(String type, bool isAr) => switch (type) {
        'session_joined' =>
          isAr ? 'تأكيد الانضمام للجلسة' : 'Session Confirmed',
        'player_joined' => isAr ? 'لاعب جديد انضم' : 'Player Joined',
        'session_cancelled' =>
          isAr ? 'تم إلغاء الجلسة' : 'Session Cancelled',
        'match_request' =>
          isAr ? 'طلب مباراة جديد' : 'New Match Request',
        'match_approved' =>
          isAr ? 'تمت الموافقة على المباراة' : 'Match Approved',
        'match_cancelled' =>
          isAr ? 'تم إلغاء المباراة' : 'Match Cancelled',
        'match_rescheduled' =>
          isAr ? 'اقتراح وقت جديد للمباراة' : 'Match Rescheduled',
        'reschedule_accepted' =>
          isAr ? 'تم قبول الوقت الجديد' : 'Reschedule Accepted',
        'reschedule_rejected' =>
          isAr ? 'تم رفض الوقت الجديد' : 'Reschedule Rejected',
        _ => '',
      };
}
