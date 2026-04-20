import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/venue_models.dart';
import '../../services/venue_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/shimmer_widget.dart';
import 'venue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<Venue> _venues   = [];
  bool _isLoading       = true;
  bool _hasError        = false;
  String _errorMessage  = '';
  String _searchQuery   = '';

  // Pagination state
  int  _currentPage   = 1;
  bool _hasMore       = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) _loadMore();
    }
  }

  Future<void> _loadVenues({bool silent = false}) async {
    if (!silent) {
      setState(() { _isLoading = true; _hasError = false; });
    }
    try {
      final result = await context.read<VenueService>().getVenuesPaged(
        q:        _searchQuery.isEmpty ? null : _searchQuery,
        page:     1,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _venues      = result.data;
          _currentPage = 1;
          _hasMore     = result.hasMore;
          _isLoading   = false;
          _hasError    = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading    = false;
          _hasError     = true;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await context.read<VenueService>().getVenuesPaged(
        q:        _searchQuery.isEmpty ? null : _searchQuery,
        page:     _currentPage + 1,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          _venues.addAll(result.data);
          _currentPage++;
          _hasMore       = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadVenues(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadVenues(silent: true),
        color: context.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title:   Text(l.appName),
              pinned:  true,
              floating: false,
              expandedHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  l.appName,
                  style: TextStyle(
                    color:      context.textPrimary,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Container(color: context.scaffoldBg),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _buildSearchBar(l),
              ),
            ),
            _buildBody(),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: context.primary, strokeWidth: 2),
                  ),
                ),
              ),
            if (!_hasMore && _venues.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      l.venuesTotal(_venues.length),
                      style: TextStyle(
                          fontSize: 12, color: context.textHint),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: TextField(
        controller: _searchController,
        onChanged:  _onSearchChanged,
        decoration: InputDecoration(
          hintText:   l.searchVenues,
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.textHint, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const VenueCardShimmer(),
            childCount: 4,
          ),
        ),
      );
    }

    if (_hasError) {
      return SliverFillRemaining(
        child: ErrorState(message: _errorMessage, onRetry: _loadVenues),
      );
    }

    if (_venues.isEmpty) {
      return SliverFillRemaining(
          child: EmptyVenuesState(onRetry: _loadVenues));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _buildVenueCard(_venues[i]),
          childCount: _venues.length,
        ),
      ),
    );
  }

  Widget _buildVenueCard(Venue venue) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VenueDetailScreen(venueId: venue.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:        context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color:        context.greenTint,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                      color: context.greenBorder, width: 0.5),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.stadium_rounded,
                        size: 52,
                        color: context.primary.withOpacity(0.25)),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        context.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: context.borderColor, width: 0.5),
                      ),
                      child: Text(l.fiveASide,
                          style: TextStyle(
                            color:      context.primary,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venue.name,
                      style: context.tt.titleMedium
                          ?.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: context.primary),
                      const SizedBox(width: 3),
                      Text(venue.city ?? l.unknownCity,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tag(Icons.sports_soccer_rounded,
                          l.sessionsAvailable, context.primary),
                      const SizedBox(width: 8),
                      _tag(
                        Icons.circle,
                        venue.isActive ? l.active : l.inactive,
                        venue.isActive
                            ? context.primary
                            : context.textHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
