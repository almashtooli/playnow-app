import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/notification_models.dart';

class NotificationInboxService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  Future<void> loadNotifications({int page = 1, int pageSize = 20}) async {
    _loading = true;
    notifyListeners();
    try {
      final json = await apiClient.get('/notifications', queryParams: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      });
      final List items = json['items'] ?? [];
      _notifications = items.map((e) => AppNotification.fromJson(e)).toList();
      _unreadCount = json['unreadCount'] ?? 0;
    } catch (e) {
      debugPrint('NotificationInboxService.loadNotifications error: $e');
      // keep stale data on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final json = await apiClient.get('/notifications/unread-count');
      _unreadCount = json['count'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationInboxService.fetchUnreadCount error: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiClient.post('/notifications/read-all');
      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          referenceId: n.referenceId,
          referenceType: n.referenceType,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationInboxService.markAllRead error: $e');
    }
  }

  Future<void> markRead(int id) async {
    try {
      await apiClient.post('/notifications/$id/read');
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        final old = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: old.id,
          title: old.title,
          body: old.body,
          type: old.type,
          referenceId: old.referenceId,
          referenceType: old.referenceType,
          isRead: true,
          createdAt: old.createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationInboxService.markRead error: $e');
    }
  }
}
