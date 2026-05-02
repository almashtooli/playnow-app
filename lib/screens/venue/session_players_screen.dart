import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard_models.dart';
import '../../models/session_models.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';

class SessionPlayersScreen extends StatefulWidget {
  final Session session;
  const SessionPlayersScreen({super.key, required this.session});

  @override
  State<SessionPlayersScreen> createState() => _SessionPlayersScreenState();
}

class _SessionPlayersScreenState extends State<SessionPlayersScreen> {
  final DashboardService _service = DashboardService();
  List<SessionPlayer> _players = [];
  bool _loading = true;
  bool _cancelled = false;

  // True when cancellation is allowed (> 60 min before session start).
  bool get _canCancelSession {
    if (_cancelled) return false;
    final now = DateTime.now();
    if (!widget.session.startsAt.isAfter(now)) return false;
    return widget.session.startsAt.difference(now).inMinutes > 60;
  }

  bool get _isSessionUpcoming => widget.session.startsAt.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _cancelled = widget.session.status == 'cancelled';
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _loading = true);
    try {
      final players = await _service.getSessionPlayers(widget.session.id);
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _checkIn(SessionPlayer player) async {
    try {
      await _service.checkIn(widget.session.id, player.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).checkedInMsg(player.name)),
        ),
      );
      _loadPlayers();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _cancelSession() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CancelReasonSheet(),
    );
    if (reason == null || !mounted) return;

    try {
      await _service.cancelSession(
        widget.session.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (!mounted) return;
      setState(() => _cancelled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sessionCancelledMsg),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(widget.session.startsAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.pitchName),
        actions: [
          if (!_cancelled && _isSessionUpcoming)
            _canCancelSession
                ? TextButton.icon(
                    onPressed: _cancelSession,
                    icon: Icon(Icons.cancel_rounded,
                        color: context.errorColor, size: 18),
                    label: Text(AppLocalizations.of(context).cancelSession,
                        style: TextStyle(
                            color: context.errorColor,
                            fontWeight: FontWeight.w700)),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_clock_rounded,
                            size: 14, color: context.textHint),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).cannotCancelWithin1Hour,
                          style: TextStyle(
                              fontSize: 11, color: context.textHint),
                        ),
                      ],
                    ),
                  ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: context.surface,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: TextStyle(color: context.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).playersCount(
                          widget.session.joinedPlayers,
                          widget.session.maxPlayers),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (_cancelled) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.errorBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.errorBorder),
                        ),
                        child: Text(AppLocalizations.of(context).cancelled,
                            style: TextStyle(
                                fontSize: 11,
                                color: context.errorColor,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: context.primary))
                : _players.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context).noPlayersYet))
                    : RefreshIndicator(
                        onRefresh: _loadPlayers,
                        color: context.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            final p = _players[index];
                            final isAttended = p.status == 'attended';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: context.borderColor, width: 0.5),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      context.greenTint,
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: context.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Row(
                                children: [
                                  Expanded(
                                    child: Text(p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  if (p.seatsReserved > 1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF39C12)
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFF39C12)
                                                .withOpacity(0.4),
                                            width: 0.5),
                                      ),
                                      child: Text(
                                        '${p.seatsReserved} spots',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFF39C12)),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(p.phone ?? AppLocalizations.of(context).noPhone),
                                trailing: isAttended
                                    ? Icon(Icons.check_circle,
                                        color: context.primary)
                                    : (_cancelled
                                        ? null
                                        : TextButton(
                                            onPressed: () => _checkIn(p),
                                            child: Text(AppLocalizations.of(context).checkIn,
                                                style: TextStyle(
                                                    color: context.primary,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          )),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Cancel reason bottom sheet ────────────────────────────────────────────────

List<String> _presetReasons(AppLocalizations l) => [
  l.reasonMaintenance,
  l.reasonWeather,
  l.reasonNotEnoughPlayers,
  l.reasonEmergency,
  l.reasonDoubleBooking,
  l.other,
];

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  String? _selected;
  final _customController = TextEditingController();
  bool _showCustomField = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _onPresetTap(String reason, AppLocalizations l) {
    setState(() {
      _selected = reason;
      _showCustomField = reason == l.other;
      if (!_showCustomField) _customController.clear();
    });
  }

  String? get _finalReason {
    if (_selected == null) return null;
    if (_showCustomField) {
      final custom = _customController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selected;
  }

  bool get _canConfirm {
    if (_selected == null) return false;
    if (_showCustomField) return _customController.text.trim().isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final presets = _presetReasons(l);
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
          Text(l.cancelSessionTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            l.cancelSessionSubtitle,
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
          const SizedBox(height: 16),

          // Preset reason chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((r) {
              final selected = _selected == r;
              return GestureDetector(
                onTap: () => _onPresetTap(r, l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.errorBg
                        : context.scaffoldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? context.errorBorder
                            : context.borderColor),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? context.errorColor : context.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Custom text field (visible only when "Other" is selected)
          if (_showCustomField) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _customController,
              maxLength: 200,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l.describeReason,
                filled: true,
                fillColor: context.scaffoldBg,
                counterStyle:
                    TextStyle(fontSize: 11, color: context.textHint),
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
                  borderSide:
                      BorderSide(color: context.errorColor, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textSecondary,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.goBack,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canConfirm
                      ? () => Navigator.pop(context, _finalReason ?? '')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.confirmCancel,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
