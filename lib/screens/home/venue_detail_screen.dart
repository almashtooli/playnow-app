import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../models/venue_models.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/venue_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/football_field_picker.dart';
import '../../widgets/seats_picker.dart';
import '../../widgets/shimmer_widget.dart';
import '../match_booking/book_match_screen.dart';
import 'video_player_screen.dart';

class VenueDetailScreen extends StatefulWidget {
  final int venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Venue? _venue;
  List<Session> _sessions = [];
  bool _loadingVenue = true;
  bool _loadingSessions = true;
  bool _sessionsError = false;
  bool _venueError = false;
  String _sessionsErrorMsg = '';
  final Set<int> _joiningSessionIds = {};

  // Pagination
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  // Filters
  DateTime? _filterDate;
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVenue();
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVenue() async {
    try {
      final venue = await context.read<VenueService>().getVenueById(
        widget.venueId,
      );
      if (mounted)
        setState(() {
          _venue = venue;
          _loadingVenue = false;
        });
    } on ApiException {
      if (mounted)
        setState(() {
          _loadingVenue = false;
          _venueError = true;
        });
    }
  }

  Future<void> _loadSessions({bool silent = false}) async {
    if (!silent)
      setState(() {
        _loadingSessions = true;
        _sessionsError = false;
      });
    try {
      DateTime? from;
      DateTime? to;
      if (_filterDate != null) {
        from = DateTime(
          _filterDate!.year,
          _filterDate!.month,
          _filterDate!.day,
          0,
          0,
          0,
        );
        to = DateTime(
          _filterDate!.year,
          _filterDate!.month,
          _filterDate!.day,
          23,
          59,
          59,
        );
      }

      final result = await context.read<SessionService>().getSessionsPaged(
        venueId: widget.venueId,
        availableOnly: _availableOnly,
        from: from,
        to: to,
        page: 1,
        pageSize: _pageSize,
      );
      if (mounted)
        setState(() {
          _sessions = result.data;
          _currentPage = 1;
          _hasMore = result.hasMore;
          _loadingSessions = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _loadingSessions = false;
          _sessionsError = true;
          _sessionsErrorMsg = e.message;
        });
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      DateTime? from;
      DateTime? to;
      if (_filterDate != null) {
        from = DateTime(
          _filterDate!.year,
          _filterDate!.month,
          _filterDate!.day,
          0,
          0,
          0,
        );
        to = DateTime(
          _filterDate!.year,
          _filterDate!.month,
          _filterDate!.day,
          23,
          59,
          59,
        );
      }

      final result = await context.read<SessionService>().getSessionsPaged(
        venueId: widget.venueId,
        availableOnly: _availableOnly,
        from: from,
        to: to,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => child!,
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
      _loadSessions();
    }
  }

  void _clearDate() {
    setState(() => _filterDate = null);
    _loadSessions();
  }

  void _toggleAvailableOnly(bool value) {
    setState(() => _availableOnly = value);
    _loadSessions();
  }

  Future<void> _joinSession(Session session) async {
    final l = AppLocalizations.of(context);
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      UiHelpers.showWarning(context, l.loginToBookSession);
      return;
    }

    // Step 1: pick seats
    final seats = await showSeatsPicker(
      context,
      remainingSpots: session.remainingSpots,
      pricePerPlayer: session.pricePerPlayer,
    );
    if (seats == null || !mounted) return;

    // Step 2: pick position on the field
    final position = await showPositionPicker(context);
    if (position == null || !mounted) return;

    // Step 3: confirm
    final total = (seats * session.pricePerPlayer).toStringAsFixed(1);
    final confirmed = await UiHelpers.confirm(
      context,
      title: l.confirmBookingTitle,
      message: '${l.reserveSpotConfirm(total, _formatDate(session.startsAt), _formatTime(session.startsAt))}'
          '\nPosition: ${position.label} — ${position.fullName} (Team ${position.team})',
      confirmText: l.bookNow,
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
        UiHelpers.showSuccess(context, l.spotReserved);
        _loadSessions(silent: true);
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _joiningSessionIds.remove(session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildInfoTab(), _buildSessionsTab(), _buildBookMatchTab()],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 56),
        title: Text(
          _venue?.name ?? AppLocalizations.of(context).venueLabel,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        background: _buildPhotoBackground(),
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: AppLocalizations.of(context).tabInfo),
          Tab(text: AppLocalizations.of(context).sessions),
          Tab(text: AppLocalizations.of(context).tabBookMatch),
        ],
      ),
    );
  }

  Widget _buildPhotoBackground() {
    return _PhotoCarousel(
      photos: _venue?.photos ?? [],
      videos: _venue?.videos ?? [],
    );
  }

  Widget _buildInfoTab() {
    if (_loadingVenue) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ShimmerWidget.rounded(width: double.infinity, height: 20),
            const SizedBox(height: 12),
            ShimmerWidget.rounded(width: 200, height: 16),
            const SizedBox(height: 20),
            ShimmerWidget.rounded(width: double.infinity, height: 80),
          ],
        ),
      );
    }
    if (_venueError || _venue == null) return ErrorState(onRetry: _loadVenue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            Icons.location_on_rounded,
            AppLocalizations.of(context).locationLabel,
            [
              _venue!.address,
              _venue!.area,
              _venue!.city,
            ].where((s) => s != null && s.isNotEmpty).join(', '),
          ),
          if (_venue!.phone != null)
            _infoCard(Icons.phone_rounded, AppLocalizations.of(context).phone, _venue!.phone!),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.greenTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.greenBorder, width: 0.5),
            ),
            child: Icon(icon, color: context.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookMatchTab() {
    if (_loadingVenue) {
      return Center(child: CircularProgressIndicator(color: context.primary));
    }
    if (_venue == null) return ErrorState(onRetry: _loadVenue);

    final auth = context.read<AuthService>();
    final pitches = _venue!.pitches ?? <Pitch>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.greenTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.greenBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: context.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).bookMatchInfoText,
                    style: TextStyle(fontSize: 13, color: context.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !auth.isLoggedIn
                  ? () => UiHelpers.showWarning(context, AppLocalizations.of(context).loginToBookMatch)
                  : () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookMatchScreen(
                            venue: _venue!,
                            pitches: pitches,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        UiHelpers.showSuccess(context, AppLocalizations.of(context).requestSentToVenue);
                      }
                    },
              icon: const Icon(Icons.sports_soccer_rounded),
              label: Text(AppLocalizations.of(context).requestMatchBooking),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadSessions(silent: true),
            color: context.primary,
            child: _buildSessionsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final hasActiveFilter = _filterDate != null || _availableOnly;
    return Container(
      color: context.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _filterDate != null
                    ? context.greenTint
                    : context.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filterDate != null
                      ? context.greenBorder
                      : context.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: _filterDate != null
                        ? context.primary
                        : context.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _filterDate != null
                        ? '${_filterDate!.day} ${_monthName(_filterDate!.month)}'
                        : AppLocalizations.of(context).pickDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _filterDate != null
                          ? context.primary
                          : context.textSecondary,
                    ),
                  ),
                  if (_filterDate != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _clearDate,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: context.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleAvailableOnly(!_availableOnly),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _availableOnly
                    ? context.greenTint
                    : context.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _availableOnly
                      ? context.greenBorder
                      : context.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _availableOnly
                        ? Icons.check_circle_rounded
                        : Icons.people_outline_rounded,
                    size: 14,
                    color: _availableOnly
                        ? context.primary
                        : context.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).availableOnly,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _availableOnly
                          ? context.primary
                          : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasActiveFilter) ...[
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterDate = null;
                  _availableOnly = false;
                });
                _loadSessions();
              },
              child: Text(
                AppLocalizations.of(context).clearAll,
                style: TextStyle(
                  fontSize: 12,
                  color: context.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_loadingSessions) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const SessionCardShimmer(),
      );
    }
    if (_sessionsError) {
      return ErrorState(message: _sessionsErrorMsg, onRetry: _loadSessions);
    }
    if (_sessions.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptySessionsState(onRetry: _loadSessions),
      );
    }
    return NotificationListener<ScrollEndNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 200) _loadMoreSessions();
        return false;
      },
      child: ListView.builder(
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
                    color: context.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (!_hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).sessionsTotal(_sessions.length),
                    style: TextStyle(fontSize: 12, color: context.textHint),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          return _buildSessionCard(_sessions[i]);
        },
      ),
    );
  }

  Widget _buildSessionCard(Session session) {
    final isFull = session.isFull;
    final isCancelled = session.status == 'cancelled';
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
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? context.borderColor.withOpacity(0.3)
                        : context.greenTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCancelled ? context.borderColor : context.greenBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(session.startsAt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isCancelled
                              ? context.textHint
                              : context.primary,
                        ),
                      ),
                      Text(
                        _formatDate(session.startsAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.pitchName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isCancelled
                              ? context.textHint
                              : context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${session.pricePerPlayer.toStringAsFixed(1)} JD',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: spotsColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isFull
                                ? AppLocalizations.of(context).full
                                : AppLocalizations.of(context).remainingSpots(spotsLeft),
                            style: TextStyle(
                              fontSize: 12,
                              color: spotsColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCancelled) _buildJoinButton(session, isFull, isJoining),
              ],
            ),
            if (!isCancelled) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: session.maxPlayers > 0
                      ? session.joinedPlayers / session.maxPlayers
                      : 0,
                  minHeight: 4,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(spotsColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).playersCount(session.joinedPlayers, session.maxPlayers),
                style: TextStyle(fontSize: 11, color: context.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton(Session session, bool isFull, bool isJoining) {
    return SizedBox(
      width: 80,
      child: ElevatedButton(
        onPressed: (isFull || isJoining) ? null : () => _joinSession(session),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        child: isJoining
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(isFull ? AppLocalizations.of(context).full : AppLocalizations.of(context).join),
      ),
    );
  }

  String _monthName(int month) =>
      AppLocalizations.of(context).shortMonth(month);

  String _formatDate(DateTime dt) => '${dt.day} ${_monthName(dt.month)}';

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<VenuePhoto> photos;
  final List<VenueVideo> videos;
  const _PhotoCarousel({required this.photos, required this.videos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final videos = widget.videos;
    final total = photos.length + videos.length;

    if (total == 0) return _placeholder(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: total,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) {
            if (i < photos.length) {
              return Image.network(
                photos[i].url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              );
            }
            final video = videos[i - photos.length];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(videoUrl: video.url),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _placeholder(context),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (total > 1)
          Positioned(
            bottom: 62,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.greenTint,
      child: Center(
        child: Icon(Icons.stadium_rounded,
            size: 64, color: context.primary.withOpacity(0.25)),
      ),
    );
  }
}
