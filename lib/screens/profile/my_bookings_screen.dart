import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/shimmer_widget.dart';
import '../match_booking/my_match_bookings_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Session> _bookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final Set<int> _pinnedLogIds = {};
  final Set<int> _removedLogIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    SessionService.refreshBookings.addListener(_onSessionChange);
  }

  void _onSessionChange() {
    if (mounted) _load(silent: true);
  }

  @override
  void dispose() {
    SessionService.refreshBookings.removeListener(_onSessionChange);
    _tabController.dispose();
    super.dispose();
  }

  List<Session> get _activeSessions {
    final now = DateTime.now();
    return _bookings
        .where((s) => s.endsAt.isAfter(now) && s.status != 'cancelled')
        .toList();
  }

  List<Session> get _pastSessions {
    final now = DateTime.now();
    final all = _bookings
        .where((s) =>
            !_removedLogIds.contains(s.id) &&
            (s.endsAt.isBefore(now) ||
                s.status == 'cancelled' ||
                s.status == 'completed'))
        .toList();
    // Pinned items float to the top
    all.sort((a, b) {
      final aPinned = _pinnedLogIds.contains(a.id) ? 0 : 1;
      final bPinned = _pinnedLogIds.contains(b.id) ? 0 : 1;
      return aPinned.compareTo(bPinned);
    });
    return all;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final service = context.read<SessionService>();
      final bookings = await service.getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _cancelBooking(Session session) async {
    final l = AppLocalizations.of(context);
    final confirmed = await UiHelpers.confirm(
      context,
      title: l.cancelBooking,
      message: l.cancelBookingForVenue(session.venueName),
      confirmText: l.yesCancelButton,
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    final service = context.read<SessionService>();
    UiHelpers.showLoading(context, message: l.cancelling);
    try {
      await service.cancelJoin(session.id);
      if (mounted) {
        UiHelpers.hideLoading(context);
        UiHelpers.showSuccess(context, l.bookingCancelledSuccess);
        _load(silent: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        UiHelpers.hideLoading(context);
        UiHelpers.showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.myBookings),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l.tabActive),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text(l.tabLogs),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyMatchBookingsScreen()),
            ),
            icon: const Icon(Icons.sports_soccer_rounded, size: 16),
            label: Text(l.sessions),
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const SessionCardShimmer(),
            )
          : _hasError
              ? ErrorState(message: _errorMessage, onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(),
                    _buildLogsTab(),
                  ],
                ),
    );
  }

  Widget _buildActiveTab() {
    final sessions = _activeSessions;
    if (sessions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptyBookingsState(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: context.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (_, i) =>
            _buildBookingCard(sessions[i], allowCancel: true),
      ),
    );
  }

  Widget _buildLogsTab() {
    final sessions = _pastSessions;
    final l = AppLocalizations.of(context);
    if (sessions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 64, color: context.textHint),
              const SizedBox(height: 12),
              Text(
                l.noPastBookings,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: context.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(l.pastBookingsEmpty,
                  style: TextStyle(fontSize: 13, color: context.textHint)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: context.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (_, i) => _buildSwipeableLogCard(sessions[i]),
      ),
    );
  }

  Widget _buildSwipeableLogCard(Session session) {
    final l = AppLocalizations.of(context);
    final isPinned = _pinnedLogIds.contains(session.id);
    return Dismissible(
      key: ValueKey('log_${session.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → pin/unpin
          setState(() {
            if (isPinned) {
              _pinnedLogIds.remove(session.id);
            } else {
              _pinnedLogIds.add(session.id);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isPinned ? l.logUnpinned : l.logPinned),
            duration: const Duration(seconds: 2),
          ));
          return false; // keep the item
        } else {
          // Swipe left → remove
          return true;
        }
      },
      onDismissed: (_) {
        setState(() => _removedLogIds.add(session.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.logRemoved),
          duration: const Duration(seconds: 2),
        ));
      },
      // Swipe right background (pin)
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: context.primary),
            const SizedBox(height: 4),
            Text(isPinned ? l.logUnpinned : l.pinToTop,
                style: TextStyle(
                    color: context.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      // Swipe left background (delete)
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.errorColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
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
      child: _buildBookingCard(session, allowCancel: false, isPinned: isPinned),
    );
  }

  Widget _buildBookingCard(Session session,
      {required bool allowCancel, bool isPinned = false}) {
    final isUpcoming = session.startsAt.isAfter(DateTime.now());
    final statusColor = _statusColor(session.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color:        context.greenTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: context.greenBorder, width: 0.5),
                      ),
                      child: Icon(Icons.sports_soccer_rounded,
                          color: context.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned) ...[
                                Icon(Icons.push_pin,
                                    size: 12, color: context.primary),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(session.venueName,
                                    style: context.tt.titleMedium
                                        ?.copyWith(fontSize: 14)),
                              ),
                            ],
                          ),
                          Text(session.pitchName,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary)),
                        ],
                      ),
                    ),
                    _statusBadge(session.status),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoChip(Icons.calendar_today_rounded,
                        _formatDate(session.startsAt)),
                    const SizedBox(width: 8),
                    _infoChip(Icons.access_time_rounded,
                        _formatTime(session.startsAt)),
                    const Spacer(),
                    Text(
                      '${session.pricePerPlayer.toStringAsFixed(1)} JD',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      context.primary,
                      ),
                    ),
                  ],
                ),
                if (allowCancel &&
                    isUpcoming &&
                    session.status == 'open') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(session),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                          AppLocalizations.of(context).cancelBooking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.errorColor,
                        side: BorderSide(color: context.errorBorder),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize:   12,
            color:      context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final l = AppLocalizations.of(context);
    final label = switch (status.toLowerCase()) {
      'open' => l.sessionOpen,
      'full' => l.sessionFull,
      'cancelled' => l.cancelled,
      'completed' => l.history,
      _ => status.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':      return context.primary;
      case 'full':      return const Color(0xFFF39C12);
      case 'cancelled': return context.errorColor;
      case 'completed': return const Color(0xFF3498DB);
      default:          return context.textHint;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${AppLocalizations.of(context).shortMonth(dt.month)}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
