import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_models.dart';
import '../../services/notification_inbox_service.dart';
import '../../theme/app_theme.dart';
import '../home/session_detail_screen.dart';
import '../match_booking/my_match_bookings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationInboxService>().loadNotifications();
    });
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationInboxService>().markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          Consumer<NotificationInboxService>(
            builder: (_, svc, __) => svc.unreadCount > 0
                ? TextButton(
                    onPressed: _markAllRead,
                    child: Text(l.markAllRead,
                        style: TextStyle(
                            color:      context.primary,
                            fontWeight: FontWeight.w600,
                            fontSize:   13)),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<NotificationInboxService>(
        builder: (_, svc, __) {
          if (svc.loading && svc.notifications.isEmpty) {
            return Center(
                child: CircularProgressIndicator(
                    color: context.primary));
          }
          if (svc.notifications.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            onRefresh: () => svc.loadNotifications(),
            color: context.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: svc.notifications.length,
              itemBuilder: (_, i) {
                final n = svc.notifications[i];
                return Column(
                  children: [
                    _buildSwipeableTile(n, svc),
                    if (i < svc.notifications.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateTo(AppNotification n) {
    final refId = n.referenceId;
    if (refId == null) return;

    final refType = n.referenceType ?? '';
    if (refType == 'session' ||
        n.type == 'session_joined' ||
        n.type == 'player_joined' ||
        n.type == 'session_cancelled') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(sessionId: refId),
        ),
      );
    } else if (refType == 'match' ||
        n.type.startsWith('match_') ||
        n.type.startsWith('reschedule_')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyMatchBookingsScreen()),
      );
    }
  }

  Widget _buildSwipeableTile(AppNotification n, NotificationInboxService svc) {
    final l = AppLocalizations.of(context);
    return Dismissible(
      key: ValueKey('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        svc.deleteNotification(n.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.notificationRemoved),
          duration: const Duration(seconds: 2),
        ));
      },
      background: Container(
        color: context.errorColor.withOpacity(0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: context.errorColor),
            const SizedBox(height: 4),
            Text(l.removelog,
                style: TextStyle(
                    color: context.errorColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: _buildTile(n, svc),
    );
  }

  Widget _buildTile(AppNotification n, NotificationInboxService svc) {
    final l = AppLocalizations.of(context);
    // Use translated title when the type is known, otherwise fall back to
    // the server-sent title.
    final translatedTitle = l.notificationTypeTitle(n.type);
    final displayTitle =
        translatedTitle.isNotEmpty ? translatedTitle : n.title;

    return InkWell(
      onTap: () {
        if (!n.isRead) svc.markRead(n.id);
        _navigateTo(n);
      },
      child: Container(
        color: n.isRead ? null : context.greenTint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color:  _typeColor(n.type, context).withOpacity(0.1),
                shape:  BoxShape.circle,
              ),
              child: Icon(_typeIcon(n.type),
                  color: _typeColor(n.type, context), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 14,
                            color:    context.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: context.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary)),
                  const SizedBox(height: 5),
                  Text(_formatTime(n.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: context.textHint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: context.textHint),
            const SizedBox(height: 12),
            Text(l.noNotificationsYet,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: context.textSecondary)),
            const SizedBox(height: 6),
            Text(l.notificationsWillAppear,
                style: TextStyle(
                    fontSize: 13, color: context.textHint)),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'session_joined' => Icons.sports_soccer_rounded,
        'player_joined' => Icons.person_add_rounded,
        'session_cancelled' => Icons.cancel_rounded,
        'match_request' => Icons.emoji_events_rounded,
        'match_approved' => Icons.check_circle_rounded,
        'match_cancelled' => Icons.cancel_rounded,
        'match_rescheduled' => Icons.schedule_rounded,
        'reschedule_accepted' => Icons.check_circle_rounded,
        'reschedule_rejected' => Icons.cancel_rounded,
        'low_attendance_warning' => Icons.group_off_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _typeColor(String type, BuildContext ctx) => switch (type) {
        'session_joined' ||
        'match_approved' ||
        'reschedule_accepted' =>
          ctx.primary,
        'session_cancelled' ||
        'match_cancelled' ||
        'reschedule_rejected' =>
          ctx.errorColor,
        'match_rescheduled' => const Color(0xFFF39C12),
        'match_request' || 'player_joined' => ctx.primary,
        'low_attendance_warning' => const Color(0xFFF39C12),
        _ => ctx.textHint,
      };

  String _formatTime(DateTime dt) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${dt.day} ${l.shortMonth(dt.month)}';
  }
}
