import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard_models.dart';
import '../../models/session_models.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/friend_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/football_field_picker.dart';
import '../../widgets/seats_picker.dart';
import 'session_chat_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final int sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  bool _loading = true;
  String? _error;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final session = await context.read<SessionService>().getSession(widget.sessionId);
      if (mounted) setState(() { _session = session; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).couldNotLoadSession;
          _loading = false;
        });
      }
    }
  }

  Future<void> _joinFromDetail() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      UiHelpers.showWarning(context, 'Please log in to join.');
      return;
    }
    final s = _session!;
    final seats = await showSeatsPicker(
      context,
      remainingSpots: s.remainingSpots,
      pricePerPlayer: s.pricePerPlayer,
    );
    if (seats == null || !mounted) return;

    final position = await showPositionPicker(context);
    if (position == null || !mounted) return;

    final l = AppLocalizations.of(context);
    final total = (seats * s.pricePerPlayer).toStringAsFixed(1);
    final confirmed = await UiHelpers.confirm(
      context,
      title: l.confirmBookingTitle,
      message: 'Reserve ${seats == 1 ? 'a spot' : '$seats spots'} at ${s.venueName}\n'
          '${_formatDate(s.startsAt)} at ${_formatTime(s.startsAt)}\n\n'
          'Position: ${position.label} — ${position.fullName} (Team ${position.team})\n'
          'Total: $total JD',
      confirmText: l.bookNow,
      confirmColor: context.primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _joining = true);
    try {
      await context.read<SessionService>().joinSession(
            s.id,
            seats: seats,
            position: position.label,
          );
      if (mounted) {
        UiHelpers.showSuccess(
            context, seats == 1 ? l.spotReserved : '$seats ${l.spotsRemaining}');
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _showPlayersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlayersSheet(
        sessionId: _session!.id,
        joinedPlayers: _session!.joinedPlayers,
        maxPlayers: _session!.maxPlayers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.sessionDetails)),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : _error != null
              ? _buildError(l)
              : _buildBody(l),
    );
  }

  Widget _buildError(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    final s = _session!;
    final statusColor = _statusColor(s.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Session card
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: context.greenTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: context.greenBorder, width: 0.5),
                            ),
                            child: Icon(Icons.sports_soccer_rounded,
                                color: context.primary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.venueName,
                                    style: context.tt.titleMedium
                                        ?.copyWith(fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(s.pitchName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.textSecondary)),
                              ],
                            ),
                          ),
                          _statusBadge(s.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _chip(Icons.calendar_today_rounded,
                              _formatDate(s.startsAt)),
                          _chip(Icons.access_time_rounded,
                              '${_formatTime(s.startsAt)} – ${_formatTime(s.endsAt)}'),
                          _chip(Icons.group_rounded,
                              '${s.joinedPlayers}/${s.maxPlayers} ${l.players}'),
                          _chip(Icons.attach_money_rounded,
                              '${s.pricePerPlayer.toStringAsFixed(1)} JD'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Players count bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.players,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${s.joinedPlayers}/${s.maxPlayers}',
                        style: TextStyle(
                            color: context.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.maxPlayers > 0
                        ? s.joinedPlayers / s.maxPlayers
                        : 0,
                    minHeight: 6,
                    backgroundColor: context.borderColor,
                    color: s.isFull ? context.errorColor : context.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.isFull
                      ? l.full
                      : l.remainingSpots(s.remainingSpots),
                  style: TextStyle(
                      fontSize: 12,
                      color: s.isFull
                          ? context.errorColor
                          : context.textHint),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // See Players button
          ElevatedButton.icon(
            onPressed: _showPlayersSheet,
            icon: const Icon(Icons.people_rounded, size: 18),
            label: Text(l.viewPlayers),
          ),
          const SizedBox(height: 12),

          // Join button — only if open, not full, and user hasn't joined yet
          if (s.isOpen && !s.isFull && !s.isJoined) ...[
            ElevatedButton.icon(
              onPressed: _joining ? null : _joinFromDetail,
              icon: _joining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sports_soccer_rounded, size: 18),
              label: Text(_joining ? l.loading : l.join),
            ),
            const SizedBox(height: 12),
          ],

          // Invite Friends button (only for open sessions)
          if (s.status == 'open')
            Consumer<FriendService>(
              builder: (_, friendSvc, __) {
                if (friendSvc.friends.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showInviteFriendsSheet(s),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(l.inviteFriends),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.primary,
                        side: BorderSide(color: context.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),

          // Chat button — only visible once the user has joined
          if (s.isJoined)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionChatScreen(
                    sessionId: s.id,
                    sessionTitle: '${s.venueName} · ${s.pitchName}',
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(l.openChat),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primary,
                side: BorderSide(color: context.primary),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showInviteFriendsSheet(Session session) async {
    final l = AppLocalizations.of(context);
    final friendSvc = context.read<FriendService>();
    final friends = friendSvc.friends;
    if (friends.isEmpty) return;

    final selected = <int>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded,
                        color: context.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(l.selectFriendsToInvite,
                        style: context.tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Divider(height: 1, color: context.borderColor),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: friends.length,
                  itemBuilder: (_, i) {
                    final f = friends[i];
                    final isSelected = selected.contains(f.userId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (v) => setSheetState(() => v == true
                          ? selected.add(f.userId)
                          : selected.remove(f.userId)),
                      title: Text(f.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      secondary: CircleAvatar(
                        backgroundColor: context.greenTint,
                        backgroundImage: f.avatarUrl != null
                            ? NetworkImage(f.avatarUrl!)
                            : null,
                        child: f.avatarUrl == null
                            ? Text(
                                f.name.isNotEmpty
                                    ? f.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: context.primary,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      activeColor: context.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            Navigator.pop(context);
                            try {
                              await friendSvc.inviteToSession(
                                  session.id, selected.toList());
                              if (mounted) {
                                UiHelpers.showSuccess(
                                    context, l.invitesSent);
                              }
                            } catch (e) {
                              if (mounted) {
                                UiHelpers.showError(
                                    context, e.toString());
                              }
                            }
                          },
                    child: Text(l.invitesSent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textHint),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final l = AppLocalizations.of(context);
    final label = switch (status.toLowerCase()) {
      'open'      => l.sessionOpen,
      'full'      => l.sessionFull,
      'cancelled' => l.cancelled,
      'completed' => l.history,
      _           => status.toUpperCase(),
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
            letterSpacing: 0.5),
      ),
    );
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'open'      => context.primary,
        'full'      => const Color(0xFFF39C12),
        'cancelled' => context.errorColor,
        'completed' => const Color(0xFF3498DB),
        _           => context.textHint,
      };

  String _formatDate(DateTime dt) {
    final l = AppLocalizations.of(context);
    return '${dt.day} ${l.shortMonth(dt.month)} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Players bottom sheet ──────────────────────────────────────────────────────

class _PlayersSheet extends StatefulWidget {
  final int sessionId;
  final int joinedPlayers;
  final int maxPlayers;

  const _PlayersSheet({
    required this.sessionId,
    required this.joinedPlayers,
    required this.maxPlayers,
  });

  @override
  State<_PlayersSheet> createState() => _PlayersSheetState();
}

class _PlayersSheetState extends State<_PlayersSheet> {
  final _service = DashboardService();
  List<SessionPlayer> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final players = await _service.getSessionPlayers(widget.sessionId);
      if (mounted) setState(() { _players = players; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Could not load players.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.people_rounded, color: context.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l.players}  ·  ${widget.joinedPlayers}/${widget.maxPlayers}',
                  style: context.tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderColor),

          // Body
          Flexible(
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: context.primary),
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40, color: context.errorColor),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.textSecondary)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _load,
                              child: Text(AppLocalizations.of(context).retry),
                            ),
                          ],
                        ),
                      )
                    : _players.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sports_soccer_rounded,
                                    size: 48,
                                    color: context.textHint),
                                const SizedBox(height: 12),
                                Text(l.noPlayersYet,
                                    style: TextStyle(
                                        color: context.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: _players.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _PlayerTile(player: _players[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final SessionPlayer player;
  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context) {
    final initial = player.name.isNotEmpty
        ? player.name[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: context.greenTint,
            backgroundImage: player.avatarUrl != null
                ? NetworkImage(player.avatarUrl!)
                : null,
            onBackgroundImageError: player.avatarUrl != null
                ? (_, __) {}
                : null,
            child: player.avatarUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: context.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Name + position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    if (player.position != null &&
                        player.position!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.greenTint,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: context.greenBorder, width: 0.5),
                        ),
                        child: Text(
                          player.position!,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.primary),
                        ),
                      ),
                    if (player.seatsReserved > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFF39C12).withOpacity(0.4),
                              width: 0.5),
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                              .reservedNSpots(player.name, player.seatsReserved),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF39C12)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Attended badge
          if (player.status == 'attended')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.greenTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.greenBorder, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: context.primary),
                  const SizedBox(width: 4),
                  Text('Attended',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
