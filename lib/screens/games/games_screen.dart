import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/football_field_picker.dart';
import '../../widgets/seats_picker.dart';
import '../../widgets/shimmer_widget.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Session> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _availableOnly = false;

  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  final Set<int> _joiningSessionIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) _loadMore();
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent)
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    try {
      final result = await context.read<SessionService>().getSessionsPaged(
        availableOnly: _availableOnly,
        from: DateTime.now(),
        page: 1,
        pageSize: _pageSize,
      );
      if (mounted)
        setState(() {
          _sessions = result.data;
          _currentPage = 1;
          _hasMore = result.hasMore;
          _isLoading = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.message;
        });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await context.read<SessionService>().getSessionsPaged(
        availableOnly: _availableOnly,
        from: DateTime.now(),
        page: _currentPage + 1,
        pageSize: _pageSize,
      );
      if (mounted)
        setState(() {
          _sessions.addAll(result.data);
          _currentPage++;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
    } on ApiException {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _toggleAvailableOnly(bool value) {
    setState(() => _availableOnly = value);
    _load(silent: true);
  }

  Future<void> _joinSession(Session session) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      UiHelpers.showWarning(context, 'Please log in to book a session.');
      return;
    }

    // Step 1: pick seats
    final seats = await showSeatsPicker(
      context,
      remainingSpots: session.remainingSpots,
      pricePerPlayer: session.pricePerPlayer,
    );
    if (seats == null || !mounted) return;

    // Step 2: pick position
    final position = await showPositionPicker(context);
    if (position == null || !mounted) return;

    // Step 3: confirm
    final total = (seats * session.pricePerPlayer).toStringAsFixed(1);
    final confirmed = await UiHelpers.confirm(
      context,
      title: 'Confirm Booking',
      message:
          'Reserve ${seats == 1 ? 'a spot' : '$seats spots'} at ${session.venueName}\n'
          '${_formatDate(session.startsAt)} at ${_formatTime(session.startsAt)}\n\n'
          'Position: ${position.label} — ${position.fullName} (Team ${position.team})\n'
          'Total: $total JD',
      confirmText: 'Book Now',
      confirmColor: context.primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _joiningSessionIds.add(session.id));
    try {
      await context.read<SessionService>().joinSession(
            session.id,
            seats: seats,
            position: position.label,
          );
      if (mounted) {
        UiHelpers.showSuccess(context, seats == 1
            ? 'Spot reserved! See you on the pitch!'
            : '$seats spots reserved! See you on the pitch!');
        _load(silent: true);
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _joiningSessionIds.remove(session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.games),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _toggleAvailableOnly(!_availableOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _availableOnly
                      ? context.primary
                      : context.borderColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: _availableOnly
                          ? Colors.white
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l.availableOnly,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _availableOnly
                            ? Colors.white
                            : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        color: context.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => const SessionCardShimmer(),
      );
    }
    if (_hasError) {
      return ErrorState(message: _errorMessage, onRetry: _load);
    }
    if (_sessions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptySessionsState(onRetry: _load),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _sessions.length + 1,
      itemBuilder: (_, i) {
        if (i == _sessions.length) {
          if (_isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                    color: context.primary, strokeWidth: 2),
              ),
            );
          }
          if (!_hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)
                      .playersCount(_sessions.length, _sessions.length),
                  style: TextStyle(
                      fontSize: 12, color: context.textHint),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return _buildGameCard(_sessions[i]);
      },
    );
  }

  Widget _buildGameCard(Session session) {
    final l         = AppLocalizations.of(context);
    final isFull    = session.isFull;
    final isJoining = _joiningSessionIds.contains(session.id);
    final spotsLeft = session.remainingSpots;
    final spotsColor = spotsLeft <= 2
        ? context.errorColor
        : spotsLeft <= 5
            ? const Color(0xFFF39C12)
            : context.primary;

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
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color:        isFull
                  ? context.borderColor.withOpacity(0.5)
                  : context.greenTint,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: isFull
                        ? context.borderColor
                        : context.greenBorder,
                    width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stadium_rounded,
                              color: isFull
                                  ? context.textHint
                                  : context.primary,
                              size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.venueName,
                              style: TextStyle(
                                color: isFull
                                    ? context.textSecondary
                                    : context.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sports_soccer_rounded,
                              color: context.textHint, size: 12),
                          const SizedBox(width: 5),
                          Text(session.pitchName,
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull
                        ? context.borderColor.withOpacity(0.8)
                        : context.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFull ? l.full : l.remainingSpots(spotsLeft),
                    style: TextStyle(
                      color:      isFull
                          ? context.textSecondary
                          : context.primary,
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date/time block
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:        context.greenTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: context.greenBorder, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(session.startsAt),
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w800,
                          color:      context.primary,
                        ),
                      ),
                      Text(
                        _formatDate(session.startsAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Progress + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l.playersCount(session.joinedPlayers,
                                session.maxPlayers),
                            style: TextStyle(
                              fontSize:   12,
                              color:      context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${session.pricePerPlayer.toStringAsFixed(1)} JD',
                            style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color:      context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: session.maxPlayers > 0
                              ? session.joinedPlayers / session.maxPlayers
                              : 0,
                          minHeight: 5,
                          backgroundColor: context.borderColor,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(spotsColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Join button
                SizedBox(
                  width: 72,
                  child: ElevatedButton(
                    onPressed: (isFull || isJoining)
                        ? null
                        : () => _joinSession(session),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isJoining
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isFull ? l.full : l.join),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
