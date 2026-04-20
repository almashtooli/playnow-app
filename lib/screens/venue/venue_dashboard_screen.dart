import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../models/venue_models.dart';
import '../../services/dashboard_service.dart';
import '../../services/match_booking_service.dart';
import '../../theme/app_theme.dart';
import 'create_session_screen.dart';
import 'session_players_screen.dart';
import 'venue_match_requests_screen.dart';

class VenueDashboardScreen extends StatefulWidget {
  const VenueDashboardScreen({super.key});

  @override
  State<VenueDashboardScreen> createState() => _VenueDashboardScreenState();
}

class _VenueDashboardScreenState extends State<VenueDashboardScreen> {
  final DashboardService _service = DashboardService();
  List<Venue> _venues = [];
  Venue? _selectedVenue;
  List<Session> _sessions = [];
  bool _loading = true;
  int _pendingMatchRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _loading = true);
    try {
      final venues = await _service.getMyVenues();
      if (!mounted) return;
      setState(() {
        _venues = venues;
        if (venues.isNotEmpty) _selectedVenue = venues.first;
        _loading = false;
      });
      if (_selectedVenue != null) _loadSessions();
      _loadPendingMatchCount();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(e.message, isError: true);
    }
  }

  Future<void> _loadPendingMatchCount() async {
    try {
      final list = await context.read<MatchBookingService>().getVenueRequests();
      if (mounted) setState(() => _pendingMatchRequests = list.length);
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    if (_selectedVenue == null) return;
    setState(() => _loading = true);
    try {
      final sessions = await _service.getVenueSessions(_selectedVenue!.id);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(e.message, isError: true);
    }
  }

  Future<void> _cancelSession(Session session) async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.cancelSessionTitle),
        content: Text(
          l.cancelSessionOnDate(DateFormat('MMM d').format(session.startsAt)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.yesCancelButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await _service.cancelSession(session.id);
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).sessionCancelledSimple,
          isError: false);
      _loadSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _sessions
        .where((s) => s.startsAt.isAfter(DateTime.now()))
        .toList();
    final past = _sessions
        .where((s) => !s.startsAt.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).venueDashboard),
      ),
      floatingActionButton: _selectedVenue != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateSessionScreen(venue: _selectedVenue!),
                  ),
                );
                if (created == true) _loadSessions();
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).createSession),
            )
          : null,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: context.primary))
          : _venues.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context).noVenueYet))
              : Column(
                  children: [
                    // Venue selector
                    if (_venues.length > 1)
                      Container(
                        color:   context.surface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: DropdownButton<Venue>(
                          isExpanded: true,
                          value: _selectedVenue,
                          items: _venues
                              .map((v) => DropdownMenuItem(
                                  value: v, child: Text(v.name)))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedVenue = v);
                            _loadSessions();
                          },
                        ),
                      ),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatCard(
                            label: AppLocalizations.of(context).sessions,
                            value: upcoming.length.toString(),
                            icon: Icons.upcoming,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: AppLocalizations.of(context).players,
                            value: upcoming
                                .fold(0,
                                    (sum, s) => sum + s.joinedPlayers)
                                .toString(),
                            icon: Icons.people,
                          ),
                        ],
                      ),
                    ),

                    // Pending match requests banner
                    if (_pendingMatchRequests > 0)
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const VenueMatchRequestsScreen(),
                            ),
                          );
                          _loadPendingMatchCount();
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color:        context.greenTint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: context.greenBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sports_soccer_rounded,
                                  color: context.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .pendingMatchBanner(
                                          _pendingMatchRequests),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize:   13,
                                    color:      context.primary,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: context.primary),
                            ],
                          ),
                        ),
                      ),

                    // View all match requests
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const VenueMatchRequestsScreen(),
                            ),
                          );
                          _loadPendingMatchCount();
                        },
                        icon: const Icon(Icons.emoji_events_rounded,
                            size: 16),
                        label: Text(
                            AppLocalizations.of(context).matchRequests),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),

                    // Sessions list
                    Expanded(
                      child: _sessions.isEmpty
                          ? Center(
                              child: Text(AppLocalizations.of(context)
                                  .noSessionsCreated))
                          : RefreshIndicator(
                              onRefresh: _loadSessions,
                              color: context.primary,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 100),
                                children: [
                                  if (upcoming.isNotEmpty) ...[
                                    Text(
                                      AppLocalizations.of(context)
                                          .upcomingSessions,
                                      style: context.tt.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ...upcoming.map(
                                      (s) => _DashSessionCard(
                                        session: s,
                                        onCancel: () =>
                                            _cancelSession(s),
                                        onViewPlayers: () =>
                                            Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SessionPlayersScreen(
                                                    session: s),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (past.isNotEmpty) ...[
                                    Text(
                                      AppLocalizations.of(context)
                                          .pastSessions,
                                      style: context.tt.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ...past.map(
                                      (s) => _DashSessionCard(
                                        session: s,
                                        onCancel: null,
                                        onViewPlayers: () =>
                                            Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SessionPlayersScreen(
                                                    session: s),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        context.greenTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: context.greenBorder, width: 0.5),
              ),
              child: Icon(icon, color: context.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.bold,
                    color:      context.primary,
                  ),
                ),
                Text(label,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _DashSessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback? onCancel;
  final VoidCallback onViewPlayers;

  const _DashSessionCard({
    required this.session,
    required this.onCancel,
    required this.onViewPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(session.startsAt);
    final timeStr =
        '${DateFormat('h:mm a').format(session.startsAt)} - ${DateFormat('h:mm a').format(session.endsAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(session.pitchName,
                      style: context.tt.titleMedium
                          ?.copyWith(fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.isFull
                        ? context.errorColor.withOpacity(0.1)
                        : context.greenTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: session.isFull
                          ? context.errorBorder
                          : context.greenBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${session.joinedPlayers}/${session.maxPlayers}',
                    style: TextStyle(
                      color: session.isFull
                          ? context.errorColor
                          : context.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 13, color: context.textHint),
                const SizedBox(width: 6),
                Text(dateStr,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.access_time,
                    size: 13, color: context.textHint),
                const SizedBox(width: 6),
                Text(timeStr,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewPlayers,
                    icon: const Icon(Icons.people, size: 16),
                    label:
                        Text(AppLocalizations.of(context).players),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: Text(AppLocalizations.of(context).cancel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.errorColor,
                        side: BorderSide(color: context.errorBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
