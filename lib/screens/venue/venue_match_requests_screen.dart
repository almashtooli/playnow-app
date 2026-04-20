import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/match_booking_models.dart';
import '../../services/match_booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_widget.dart';

class VenueMatchRequestsScreen extends StatefulWidget {
  const VenueMatchRequestsScreen({super.key});

  @override
  State<VenueMatchRequestsScreen> createState() =>
      _VenueMatchRequestsScreenState();
}

class _VenueMatchRequestsScreenState extends State<VenueMatchRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<MatchBooking> _pending = [];
  List<MatchBooking> _history = [];
  bool _loadingPending = true;
  bool _loadingHistory = true;


  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadPending();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    try {
      final list = await context.read<MatchBookingService>().getVenueRequests();
      if (mounted) setState(() { _pending = list; _loadingPending = false; });
    } on ApiException {
      if (mounted) setState(() => _loadingPending = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final approved = await context.read<MatchBookingService>()
          .getVenueRequests(status: 'approved');
      final cancelled = await context.read<MatchBookingService>()
          .getVenueRequests(status: 'cancelled');
      if (mounted) {
        setState(() {
          _history = [...approved, ...cancelled]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _loadingHistory = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _approve(MatchBooking b) async {
    final l = AppLocalizations.of(context);
    double? pricePerPlayer;

    // For 1-team bookings, require a price before creating the open session
    if (b.teamsCount == 1) {
      pricePerPlayer = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PriceInputSheet(
          booking: b,
          title: l.setPricePerPlayer,
          subtitle: l.spotsSubtitle(b.teamSize * 2, b.teamSize, b.teamSize),
        ),
      );
      if (pricePerPlayer == null || !mounted) return;
    } else {
      final ok = await UiHelpers.confirm(
        context,
        title: l.approveFullMatch,
        message:
            '${l.approveMatchConfirm(b.requestedByName ?? l.players, b.pitchName)}\n'
            '${_fmtDt(b.requestedStartsAt)}  ${_fmtTime(b.requestedStartsAt)} – ${_fmtTime(b.requestedEndsAt)}',
        confirmText: l.approve,
        confirmColor: context.primary,
      );
      if (!ok || !mounted) return;
    }

    try {
      await context.read<MatchBookingService>().approve(b.id, pricePerPlayer: pricePerPlayer);
      if (mounted) {
        final msg = b.teamsCount == 1
            ? AppLocalizations.of(context).approvedSessionCreated(b.teamSize * 2)
            : AppLocalizations.of(context).bookingApproved;
        UiHelpers.showSuccess(context, msg);
        _loadPending();
        _loadHistory();
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _cancel(MatchBooking b) async {
    final l = AppLocalizations.of(context);
    final ok = await UiHelpers.confirm(
      context,
      title: l.cancelMatchRequest,
      message: 'Cancel this match request? The player will be notified.',
      confirmText: l.cancel,
      confirmColor: Colors.red,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<MatchBookingService>().cancel(b.id);
      if (mounted) {
        UiHelpers.showSuccess(context, AppLocalizations.of(context).bookingCancelled);
        _loadPending();
        _loadHistory();
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  Future<void> _reschedule(MatchBooking b) async {
    DateTime? newDate;
    TimeOfDay? newStart;
    TimeOfDay? newEnd;
    double? price;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RescheduleSheet(
        booking: b,
        onConfirm: (date, start, end, p) {
          newDate = date;
          newStart = start;
          newEnd = end;
          price = p;
        },
      ),
    );

    if (newDate == null || newStart == null || newEnd == null) return;
    if (b.teamsCount == 1 && price == null) return;
    if (!mounted) return;

    final startsAt = DateTime(newDate!.year, newDate!.month, newDate!.day, newStart!.hour, newStart!.minute);
    final endsAt   = DateTime(newDate!.year, newDate!.month, newDate!.day, newEnd!.hour,   newEnd!.minute);

    try {
      await context.read<MatchBookingService>().reschedule(b.id, startsAt, endsAt, pricePerPlayer: price);
      if (mounted) {
        UiHelpers.showSuccess(context, AppLocalizations.of(context).newTimeProposedMsg);
        _loadPending();
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.matchRequests),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: '${l.pending} (${_pending.length})'),
            Tab(text: l.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPendingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_loadingPending) return _shimmerList();
    if (_pending.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: context.textHint),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).noPendingRequests,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: context.textSecondary)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPending,
      color: context.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        itemBuilder: (_, i) => _buildRequestCard(_pending[i], showActions: true),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) return _shimmerList();
    if (_history.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noHistory,
            style: TextStyle(
                color: context.textSecondary, fontSize: 15)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: context.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (_, i) =>
            _buildRequestCard(_history[i], showActions: false),
      ),
    );
  }

  Widget _buildRequestCard(MatchBooking b, {required bool showActions}) {
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
                Icon(
                    b.teamsCount == 2
                        ? Icons.emoji_events_rounded
                        : Icons.sports_soccer_rounded,
                    color: statusColor,
                    size: 20),
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
                if (b.requestedByName != null)
                  _row(Icons.person_rounded, b.requestedByName!,
                      bold: true),
                if (b.requestedByPhone != null)
                  _row(Icons.phone_rounded, b.requestedByPhone!),
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
                    '${b.teamsCount} team${b.teamsCount > 1 ? 's' : ''} × ${b.teamSize} players'),
                if (b.notes != null && b.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _row(Icons.notes_rounded, b.notes!),
                ],

                // Rescheduled waiting on player
                if (b.isRescheduled && b.proposedStartsAt != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        context.greenTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: context.greenBorder, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            color: context.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context).newTime}: ${_fmtDt(b.proposedStartsAt!)} ${_fmtTime(b.proposedStartsAt!)} – ${_fmtTime(b.proposedEndsAt!)}',
                            style: TextStyle(
                                fontSize: 12, color: context.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons
                if (showActions && (b.isPending || b.isRescheduled)) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancel(b),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.errorColor,
                            side: BorderSide(
                                color: context.errorBorder),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: Text(
                              AppLocalizations.of(context).decline,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reschedule(b),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: Text(
                              AppLocalizations.of(context).newTime,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(b),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: Text(
                              AppLocalizations.of(context).approve,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: context.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          bold ? FontWeight.w700 : FontWeight.normal,
                      color: context.textPrimary)),
            ),
          ],
        ),
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

  Widget _shimmerList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWidget.rounded(width: double.infinity, height: 130),
        ),
      );

  Color _statusColor(String s) => switch (s) {
        'approved' => context.primary,
        'cancelled' => context.errorColor,
        'rescheduled' => const Color(0xFFF39C12),
        _ => context.primary,
      };

  String _statusLabel(String s) {
    final l = AppLocalizations.of(context);
    return switch (s) {
      'approved' => l.approved,
      'cancelled' => l.declined,
      'rescheduled' => l.newTimeProposed,
      _ => l.pending,
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

// ── Price input bottom sheet (used before approving a 1-team booking) ─────────

class _PriceInputSheet extends StatefulWidget {
  final MatchBooking booking;
  final String title;
  final String subtitle;

  const _PriceInputSheet({
    required this.booking,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_PriceInputSheet> createState() => _PriceInputSheetState();
}

class _PriceInputSheetState extends State<_PriceInputSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_controller.text);
    final valid = price != null && price >= 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(widget.subtitle,
              style: TextStyle(fontSize: 12, color: context.textSecondary)),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).pricePerPlayer,
              prefixIcon: const Icon(Icons.attach_money_rounded),
              filled: true,
              fillColor: context.scaffoldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primary),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: valid
                  ? () => Navigator.pop(context, price)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.of(context).confirmAndApprove,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reschedule bottom sheet ───────────────────────────────────────────────────

class _RescheduleSheet extends StatefulWidget {
  final MatchBooking booking;
  final void Function(DateTime date, TimeOfDay start, TimeOfDay end, double? price) onConfirm;

  const _RescheduleSheet({required this.booking, required this.onConfirm});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => child!,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? TimeOfDay.fromDateTime(widget.booking.requestedStartsAt)
          : TimeOfDay.fromDateTime(widget.booking.requestedEndsAt),
      builder: (ctx, child) => child!,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _start = picked;
        else _end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).proposeNewTime,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${AppLocalizations.of(context).playerRequested} ${_fmtDt(widget.booking.requestedStartsAt)}  ${_fmtTime(widget.booking.requestedStartsAt)} – ${_fmtTime(widget.booking.requestedEndsAt)}',
              style: TextStyle(fontSize: 12, color: context.textSecondary)),
          const SizedBox(height: 20),
          _tile(
            Icons.calendar_today_rounded,
            AppLocalizations.of(context).date,
            _date != null ? _fmtDt(_date!) : AppLocalizations.of(context).selectDate,
            _pickDate,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tile(
                  Icons.access_time_rounded,
                  AppLocalizations.of(context).start,
                  _start != null ? _start!.format(context) : '--:--',
                  () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  Icons.access_time_rounded,
                  AppLocalizations.of(context).end,
                  _end != null ? _end!.format(context) : '--:--',
                  () => _pickTime(false),
                ),
              ),
            ],
          ),
          if (widget.booking.teamsCount == 1) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).pricePerPlayer,
                prefixIcon: const Icon(Icons.attach_money_rounded),
                filled: true,
                fillColor: context.scaffoldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.primary),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.booking.teamSize * 2} total spots — ${widget.booking.teamSize} reserved, ${widget.booking.teamSize} open for others.',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final bool timeReady = _date != null && _start != null && _end != null;
                final bool priceReady = widget.booking.teamsCount != 1 ||
                    (double.tryParse(_priceController.text) != null &&
                        double.parse(_priceController.text) >= 0);
                return timeReady && priceReady;
              }()
                  ? () {
                      widget.onConfirm(
                        _date!, _start!, _end!,
                        widget.booking.teamsCount == 1
                            ? double.tryParse(_priceController.text)
                            : null,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.of(context).proposeThisTime,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
      IconData icon, String label, String value, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: context.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: context.textHint)),
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: context.textPrimary)),
                ],
              ),
            ],
          ),
        ),
      );

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
