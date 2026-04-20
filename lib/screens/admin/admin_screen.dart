import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/venue_models.dart';
import '../../services/venue_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_error_states.dart';
import '../../widgets/shimmer_widget.dart';
import 'add_venue_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Venue> _venues = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent)
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    try {
      final service = context.read<VenueService>();
      final venues = await service.getAllVenuesAdmin();
      if (mounted)
        setState(() {
          _venues = venues;
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

  Future<void> _toggleVenue(Venue venue) async {
    final action = venue.isActive ? 'deactivate' : 'activate';
    final l = AppLocalizations.of(context);
    final confirmed = await UiHelpers.confirm(
      context,
      title: venue.isActive ? '${l.deactivate} ${l.myVenue}' : '${l.activate} ${l.myVenue}',
      message: venue.isActive
          ? l.deactivateVenueConfirm(venue.name)
          : l.activateVenueConfirm(venue.name),
      confirmText: venue.isActive ? l.deactivate : l.activate,
      isDangerous: venue.isActive,
      confirmColor: venue.isActive ? context.errorColor : context.primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processingIds.add(venue.id));
    try {
      final service = context.read<VenueService>();
      if (venue.isActive) {
        await service.deactivateVenue(venue.id);
      } else {
        await service.activateVenue(venue.id);
      }
      if (mounted) {
        UiHelpers.showSuccess(
          context,
          '"${venue.name}" ${action}d successfully.',
        );
        _load(silent: true);
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _processingIds.remove(venue.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _venues.where((v) => v.isActive).length;
    final inactiveCount = _venues.where((v) => !v.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).adminPanel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddVenueScreen()),
          );
          if (created == true) _load(silent: true);
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addVenue),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        color: context.primary,
        child: _buildBody(activeCount, inactiveCount),
      ),
    );
  }

  Widget _buildBody(int activeCount, int inactiveCount) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWidget.rounded(
            width: double.infinity,
            height: 88,
            radius: 14,
          ),
        ),
      );
    }

    if (_hasError) {
      return ErrorState(message: _errorMessage, onRetry: _load);
    }

    if (_venues.isEmpty) {
      final l = AppLocalizations.of(context);
      return EmptyState(
        icon: Icons.business_outlined,
        title: l.noVenuesYet,
        subtitle: l.venuesWillAppear,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 80 for FAB space
      children: [
        // Stats row
        Builder(builder: (context) {
          final l = AppLocalizations.of(context);
          return Row(
            children: [
              _statCard(l.active, activeCount, Icons.check_circle_outline),
              const SizedBox(width: 12),
              _statCard(l.inactive, inactiveCount,
                  Icons.pause_circle_outline),
            ],
          );
        }),
        const SizedBox(height: 20),

        if (_venues.any((v) => v.isActive)) ...[
          _sectionHeader(
              AppLocalizations.of(context).activeVenues),
          const SizedBox(height: 8),
          ..._venues.where((v) => v.isActive).map(_venueCard),
          const SizedBox(height: 16),
        ],
        if (_venues.any((v) => !v.isActive)) ...[
          _sectionHeader(
              AppLocalizations.of(context).inactiveVenues),
          const SizedBox(height: 8),
          ..._venues.where((v) => !v.isActive).map(_venueCard),
        ],
      ],
    );
  }

  Widget _statCard(String label, int count, IconData icon) {
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
                Text(count.toString(),
                    style: TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.bold,
                        color:      context.primary)),
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

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color:        context.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: context.tt.titleMedium?.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _venueCard(Venue venue) {
    final isProcessing = _processingIds.contains(venue.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: venue.isActive
              ? context.greenBorder
              : context.borderColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        venue.isActive
                  ? context.greenTint
                  : context.borderColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.stadium_rounded,
                color: venue.isActive
                    ? context.primary
                    : context.textHint,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name, style: context.tt.titleMedium
                    ?.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  [venue.area, venue.city]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', '),
                  style: TextStyle(
                      fontSize: 11,
                      color:    context.textSecondary),
                ),
              ],
            ),
          ),
          isProcessing
              ? SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.primary),
                )
              : TextButton(
                  onPressed: () => _toggleVenue(venue),
                  style: TextButton.styleFrom(
                    foregroundColor: venue.isActive
                        ? context.errorColor
                        : context.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: venue.isActive
                            ? context.errorBorder
                            : context.greenBorder,
                      ),
                    ),
                  ),
                  child: Text(
                    venue.isActive
                        ? AppLocalizations.of(context).deactivate
                        : AppLocalizations.of(context).activate,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
        ],
      ),
    );
  }
}
