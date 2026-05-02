import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/friend_models.dart';
import '../../services/friend_service.dart';
import '../../theme/app_theme.dart';
import 'dm_chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Stored reference so dispose() never calls context.read on a dead element
  FriendService? _friendService;

  List<PublicUser> _searchResults = [];
  List<PublicUser> _randomUsers = [];
  bool _searching = false;
  bool _loadingRandom = false;
  String _searchQuery = '';
  String? _searchError;

  int _requestCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_friendService == null) {
      _friendService = context.read<FriendService>();
      _friendService!.addListener(_onFriendServiceChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _friendService!.loadFriends();
      _friendService!.loadIncomingRequests().then((_) {
        if (mounted) setState(() => _requestCount = _friendService!.incomingRequests.length);
      });
    });
  }

  void _onTabChanged() {
    if (_tab.index == 2 && _randomUsers.isEmpty && !_loadingRandom) {
      _loadRandomUsers();
    }
  }

  Future<void> _loadRandomUsers() async {
    setState(() => _loadingRandom = true);
    try {
      final results = await context.read<FriendService>().getRandomUsers();
      if (mounted) setState(() => _randomUsers = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRandom = false);
    }
  }

  void _onFriendServiceChanged() {
    if (mounted) {
      setState(() => _requestCount = _friendService?.incomingRequests.length ?? 0);
    }
  }

  @override
  void dispose() {
    _friendService?.removeListener(_onFriendServiceChanged);
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _searchError = null;
    });
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _doSearch(value));
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await context.read<FriendService>().searchUsers(q);
      if (mounted) setState(() => _searchResults = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _searchError = e.message);
    } catch (e) {
      if (mounted) setState(() => _searchError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.friends),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: l.myFriends),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.friendRequests),
                  if (_requestCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_requestCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(icon: const Icon(Icons.search_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildMyFriendsTab(l),
          _buildRequestsTab(l),
          _buildSearchTab(l),
        ],
      ),
    );
  }

  // ── My Friends ─────────────────────────────────────────────────────────────

  Widget _buildMyFriendsTab(AppLocalizations l) {
    return Consumer<FriendService>(
      builder: (_, svc, __) {
        if (svc.loading && svc.friends.isEmpty) {
          return Center(
              child: CircularProgressIndicator(color: context.primary));
        }
        if (svc.friends.isEmpty) {
          return _emptyState(
            Icons.people_outline_rounded,
            l.noFriendsYet,
            l.addFriendsHint,
          );
        }
        return RefreshIndicator(
          onRefresh: () => svc.loadFriends(),
          color: context.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _friendTile(svc.friends[i], svc, l),
                    childCount: svc.friends.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _friendTile(Friend friend, FriendService svc, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.greenTint,
          backgroundImage: friend.avatarUrl != null
              ? NetworkImage(friend.avatarUrl!)
              : null,
          child: friend.avatarUrl == null
              ? Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: context.primary, fontWeight: FontWeight.w800),
                )
              : null,
        ),
        title: Text(friend.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: friend.position != null
            ? Text(friend.position!,
                style:
                    TextStyle(fontSize: 12, color: context.textSecondary))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat_bubble_outline_rounded,
                  color: context.primary, size: 20),
              tooltip: l.messageFriend,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DmChatScreen(
                    friendId: friend.userId,
                    friendName: friend.name,
                    friendAvatarUrl: friend.avatarUrl,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.person_remove_outlined,
                  color: context.errorColor, size: 20),
              tooltip: l.removeFriend,
              onPressed: () => _confirmRemoveFriend(friend, svc, l),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveFriend(
      Friend friend, FriendService svc, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.removeFriend),
        content: Text(l.removeFriendConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.yes,
                  style: TextStyle(color: context.errorColor))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await svc.removeFriend(friend.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.friendRemoved)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  // ── Friend Requests ────────────────────────────────────────────────────────

  Widget _buildRequestsTab(AppLocalizations l) {
    return Consumer<FriendService>(
      builder: (_, svc, __) {
        if (svc.incomingRequests.isEmpty) {
          return _emptyState(
            Icons.inbox_rounded,
            l.noFriendRequests,
            '',
          );
        }
        return RefreshIndicator(
          onRefresh: () => svc.loadIncomingRequests(),
          color: context.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _requestTile(svc.incomingRequests[i], svc, l),
                    childCount: svc.incomingRequests.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _requestTile(
      FriendRequest req, FriendService svc, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.greenTint,
            backgroundImage: req.senderAvatarUrl != null
                ? NetworkImage(req.senderAvatarUrl!)
                : null,
            child: req.senderAvatarUrl == null
                ? Text(
                    req.senderName.isNotEmpty
                        ? req.senderName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: context.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.senderName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  _formatTime(req.createdAt, l),
                  style: TextStyle(fontSize: 11, color: context.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Reject
          OutlinedButton(
            onPressed: () => _rejectRequest(req, svc, l),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              foregroundColor: context.errorColor,
              side: BorderSide(color: context.errorBorder),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            child: Text(l.reject),
          ),
          const SizedBox(width: 6),
          // Accept
          ElevatedButton(
            onPressed: () => _acceptRequest(req, svc, l),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            child: Text(l.accept),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
      FriendRequest req, FriendService svc, AppLocalizations l) async {
    try {
      await svc.acceptRequest(req.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.friendAccepted)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _rejectRequest(
      FriendRequest req, FriendService svc, AppLocalizations l) async {
    try {
      await svc.rejectRequest(req.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.friendRejected)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  // ── Search Users ───────────────────────────────────────────────────────────

  Widget _buildSearchTab(AppLocalizations l) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l.searchPlayers,
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
          ),
        ),
        if (_searching)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
                child: CircularProgressIndicator(color: context.primary)),
          )
        else if (_searchError != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(
                Icons.error_outline_rounded, _searchError!, ''),
          )
        else if (_searchQuery.trim().isEmpty)
          if (_loadingRandom)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: CircularProgressIndicator(color: context.primary)),
            )
          else if (_randomUsers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l.suggestedPlayers,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _searchResultTile(_randomUsers[i], l,
                      onRequestSent: (updated) {
                    setState(() {
                      final idx =
                          _randomUsers.indexWhere((u) => u.id == updated.id);
                      if (idx != -1) _randomUsers[idx] = updated;
                    });
                  }),
                  childCount: _randomUsers.length,
                ),
              ),
            ),
          ] else
            SliverFillRemaining(
              hasScrollBody: false,
              child: _emptyState(
                  Icons.person_search_rounded, l.startSearching, ''),
            )
        else if (_searchResults.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(
                Icons.search_off_rounded,
                'No players found for "$_searchQuery"',
                ''),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _searchResultTile(_searchResults[i], l),
                childCount: _searchResults.length,
              ),
            ),
          ),

      ],
    );
  }

  Widget _searchResultTile(PublicUser user, AppLocalizations l,
      {void Function(PublicUser updated)? onRequestSent}) {
    final isFriend = user.friendStatus == 'friends';
    final isPending = user.friendStatus == 'request_sent' ||
        user.friendStatus == 'request_received';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.greenTint,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: context.primary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (user.position != null)
                  Text(user.position!,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
          if (isFriend)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.greenTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.greenBorder, width: 0.5),
              ),
              child: Text(l.alreadyFriends,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.primary)),
            )
          else if (isPending)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.borderColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l.requestPending,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary)),
            )
          else
            SizedBox(
              width: 130,
              child: ElevatedButton.icon(
                onPressed: () => _sendRequest(user, l, onRequestSent: onRequestSent),
                icon: const Icon(Icons.person_add_rounded, size: 14),
                label: Text(l.sendFriendRequest),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(PublicUser user, AppLocalizations l,
      {void Function(PublicUser updated)? onRequestSent}) async {
    try {
      await context.read<FriendService>().sendFriendRequest(user.id);
      if (mounted) {
        final updated = PublicUser(
          id: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl,
          position: user.position,
          friendStatus: 'request_sent',
        );
        setState(() {
          final idx = _searchResults.indexWhere((u) => u.id == user.id);
          if (idx != -1) _searchResults[idx] = updated;
        });
        onRequestSent?.call(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.friendRequestSent)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.textHint),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: context.textHint)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    return l.daysAgo(diff.inDays);
  }
}
