import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => saveFcmToken());
    FirebaseMessaging.onMessage.listen((message) {
      final type = message.data['type'] as String? ?? '';
      final translatedTitle = _translateType(type, _isArCached);
      final title = translatedTitle.isNotEmpty ? translatedTitle : (message.notification?.title ?? '');
      final body = message.notification?.body ?? '';
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await apiClient.post('/notifications/token', body: {'token': token});
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  static bool _isArCached = false;
  static void setLocaleAr(bool isAr) => _isArCached = isAr;

  static String _translateType(String type, bool isAr) => switch (type) {
        'session_joined'      => isAr ? 'تأكيد الانضمام للجلسة' : 'Session Confirmed',
        'player_joined'       => isAr ? 'لاعب جديد انضم' : 'Player Joined',
        'session_cancelled'   => isAr ? 'تم إلغاء الجلسة' : 'Session Cancelled',
        'match_request'       => isAr ? 'طلب مباراة جديد' : 'New Match Request',
        'match_approved'      => isAr ? 'تمت الموافقة على المباراة' : 'Match Approved',
        'match_cancelled'     => isAr ? 'تم إلغاء المباراة' : 'Match Cancelled',
        'match_rescheduled'   => isAr ? 'اقتراح وقت جديد للمباراة' : 'Match Rescheduled',
        'reschedule_accepted' => isAr ? 'تم قبول الوقت الجديد' : 'Reschedule Accepted',
        'reschedule_rejected' => isAr ? 'تم رفض الوقت الجديد' : 'Reschedule Rejected',
        _ => '',
      };
}
