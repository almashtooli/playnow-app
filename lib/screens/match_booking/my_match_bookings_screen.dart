import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/match_booking_models.dart';
import '../../screens/games/games_screen.dart';
import '../../services/match_booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/shimmer_widget.dart';

class MyMatchBookingsScreen extends StatefulWidget {
  const MyMatchBookingsScreen({super.key});

  @override
  State<MyMatchBookingsScreen> createState() => _MyMatchBookingsScreenState();
}

class _MyMatchBookingsScreenState extends State<MyMatchBookingsScreen> {
  List<MatchBooking> _bookings = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final list = await context.read<MatchBookingService>().getMyBookings();
      if (mounted) setState(() { _bookings = list; _loading = false; });
    } on ApiException {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  Future<void> _cancel(MatchBooking b) async {
    final l = AppLocalizations.of(context);
    final ok = await UiHelpers.confirm(
      context,
      title: l.cancelMatchRequest,
      message: l.cancelMatchConfirm,
      confirmText: l.cancelRequest,
      confirmColor: context.errorColor,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MatchBookingService>().cancel(b.id);
      if (mounted) { UiHelpers.showSuccess(context, AppLocalizations.of(context).bookingCancelled); _load(); }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _acceptReschedule(MatchBooking b) async {
    final l = AppLocalizations.of(context);
    final ok = await UiHelpers.confirm(
      context,
      title: l.acceptNewTime,
      message:
          '${l.acceptNewTimeConfirm}\n${_fmtDt(b.proposedStartsAt!)} – ${_fmtTime(b.proposedEndsAt!)}',
      confirmText: l.accept,
      confirmColor: context.primary,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MatchBookingService>().acceptReschedule(b.id);
      if (mounted) { UiHelpers.showSuccess(context, AppLocalizations.of(context).timeAccepted); _load(); }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _rejectReschedule(MatchBooking b) async {
    final l = AppLocalizations.of(context);
    final ok = await UiHelpers.confirm(
      context,
      title: l.rejectNewTime,
      message: l.rejectNewTimeConfirm,
      confirmText: l.reject,
      confirmColor: context.errorColor,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MatchBookingService>().rejectReschedule(b.id);
      if (mounted) { UiHelpers.showSuccess(context, AppLocalizations.of(context).timeRejected); _load(); }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.myMatchRequests)),
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWidget.rounded(width: double.infinity, height: 120),
        ),
      );
    }
    if (_error) return ErrorState(onRetry: _load);
    if (_bookings.isEmpty) {
      final l = AppLocalizations.of(context);
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Icon(Icons.sports_soccer_rounded,
                  size: 64, color: context.textHint),
              const SizedBox(height: 12),
              Text(l.noMatchRequestsYet,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: context.textSecondary)),
              const SizedBox(height: 6),
              Text(l.bookPitchHint,
                  style: TextStyle(
                      fontSize: 13, color: context.textHint)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (_, i) => _buildCard(_bookings[i]),
    );
  }

  Widget _buildCard(MatchBooking b) {
    final statusColor = _statusColor(b.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(b.teamsCount == 2
                    ? Icons.emoji_events_rounded
                    : Icons.sports_soccer_rounded,
                    color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(b.typeLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: statusColor)),
                ),
                _statusBadge(b.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.stadium_rounded, b.venueName),
                const SizedBox(height: 6),
                _row(Icons.sports_outlined, b.pitchName),
                const SizedBox(height: 6),
                _row(Icons.calendar_today_rounded,
                    _fmtDt(b.requestedStartsAt)),
                const SizedBox(height: 6),
                _row(Icons.access_time_rounded,
                    '${_fmtTime(b.requestedStartsAt)} – ${_fmtTime(b.requestedEndsAt)}'),
                const SizedBox(height: 6),
                _row(Icons.people_rounded,
                    AppLocalizations.of(context).teamsAndPlayers(b.teamsCount, b.teamSize)),
                if (b.notes != null && b.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _row(Icons.notes_rounded, b.notes!),
                ],

                // Rescheduled: proposed time block
                if (b.isRescheduled && b.proposedStartsAt != null) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final l = AppLocalizations.of(context);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        context.greenTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: context.greenBorder, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.venueProposedNewTime,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: context.primary)),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmtDt(b.proposedStartsAt!)}  ${_fmtTime(b.proposedStartsAt!)} – ${_fmtTime(b.proposedEndsAt!)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13,
                                  color: context.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectReschedule(b),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.errorColor,
                                      side: BorderSide(
                                          color: context.errorBorder),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(l.reject,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _acceptReschedule(b),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(l.accept,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // Approved 1-team booking: session was created
                if (b.isApproved && b.teamsCount == 1 && b.sessionId != null) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final l = AppLocalizations.of(context);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        context.greenTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: context.greenBorder, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: context.primary, size: 15),
                                const SizedBox(width: 6),
                                Text(l.sessionCreated,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: context.primary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.sessionCreatedDesc(b.teamSize, b.teamSize),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const GamesScreen()),
                                ),
                                icon: const Icon(
                                    Icons.sports_soccer_rounded,
                                    size: 16),
                                label: Text(l.viewInGamesTab,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // Cancel button (pending or rescheduled)
                if (b.isPending || b.isRescheduled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _cancel(b),
                      style: TextButton.styleFrom(
                        foregroundColor: context.errorColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                          AppLocalizations.of(context).cancelRequest,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
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

  Widget _row(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: context.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: context.textPrimary)),
          ),
        ],
      );

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'approved'    => context.primary,
        'cancelled'   => context.errorColor,
        'rescheduled' => const Color(0xFFF39C12),
        _             => context.primary,
      };

  String _statusLabel(String s) {
    final l = AppLocalizations.of(context);
    return switch (s) {
      'approved' => l.statusApproved,
      'cancelled' => l.statusCancelled,
      'rescheduled' => l.statusNewTimeProposed,
      _ => l.statusPending,
    };
  }

  String _fmtDt(DateTime dt) {
    final l = AppLocalizations.of(context);
    return '${dt.day} ${l.shortMonth(dt.month)} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
