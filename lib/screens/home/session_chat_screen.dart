import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_models.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class SessionChatScreen extends StatefulWidget {
  final int sessionId;
  final String sessionTitle;

  const SessionChatScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<SessionChatScreen> createState() => _SessionChatScreenState();
}

class _SessionChatScreenState extends State<SessionChatScreen> {
  late final ChatService _chat;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chat = ChatService(widget.sessionId);
    _chat.addListener(_onNewMessage);
    _chat.init();
  }

  @override
  void dispose() {
    _chat.removeListener(_onNewMessage);
    _chat.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await _chat.sendMessage(text);
  }

  void _showMemberProfile(ChatMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberProfileSheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _chat,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.sessionChat, style: const TextStyle(fontSize: 16)),
              Text(widget.sessionTitle,
                  style: TextStyle(
                      fontSize: 12, color: context.textSecondary)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _MembersBar(onTap: _showMemberProfile),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _MessageList(scrollController: _scrollController)),
            _InputBar(
              controller: _inputController,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Members bar (horizontal scroll of avatars) ────────────────────────────────

class _MembersBar extends StatelessWidget {
  final void Function(ChatMember) onTap;
  const _MembersBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (_, chat, __) {
        if (chat.loadingMembers) {
          return SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: context.primary),
              ),
            ),
          );
        }
        return SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: chat.members.length,
            itemBuilder: (_, i) {
              final m = chat.members[i];
              return GestureDetector(
                onTap: () => onTap(m),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      _Avatar(name: m.name, url: m.avatarUrl, radius: 20),
                      if (m.isOwner)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: context.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.surface, width: 1.5),
                            ),
                            child: const Icon(Icons.star_rounded,
                                size: 7, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  const _MessageList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (_, chat, __) {
        if (chat.loadingMessages) {
          return Center(
              child: CircularProgressIndicator(color: context.primary));
        }
        if (chat.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 48, color: context.textHint),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).noChatMessagesYet,
                  style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final myId = context.read<AuthService>().currentUser?.id;

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: chat.messages.length,
          itemBuilder: (_, i) {
            final msg = chat.messages[i];
            final isMe = msg.userId == myId;
            final showAvatar = !isMe &&
                (i == 0 || chat.messages[i - 1].userId != msg.userId);
            final showName = !isMe &&
                (i == 0 || chat.messages[i - 1].userId != msg.userId);
            return _MessageBubble(
              message: msg,
              isMe: isMe,
              showAvatar: showAvatar,
              showName: showName,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message.sentAt);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar (others only)
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showAvatar
                  ? _Avatar(
                      name: message.userName,
                      url: message.userAvatarUrl,
                      radius: 16)
                  : const SizedBox(width: 32),
            ),

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.userName,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.primary),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? context.primary : context.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: context.borderColor, width: 0.5),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : context.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    time,
                    style: TextStyle(
                        fontSize: 10, color: context.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<ChatService>(
      builder: (_, chat, __) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(
                top: BorderSide(color: context.borderColor, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l.typeMessage,
                    counterText: '',
                    filled: true,
                    fillColor: context.scaffoldBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          BorderSide(color: context.borderColor, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          BorderSide(color: context.borderColor, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          BorderSide(color: context.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: Material(
                  color: context.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: chat.sending ? null : onSend,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: chat.sending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Member profile bottom sheet ───────────────────────────────────────────────

class _MemberProfileSheet extends StatelessWidget {
  final ChatMember member;
  const _MemberProfileSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          _Avatar(name: member.name, url: member.avatarUrl, radius: 44),
          const SizedBox(height: 16),

          // Name
          Text(
            member.name,
            style: context.tt.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),

          // Owner badge
          if (member.isOwner) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.greenTint,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: context.greenBorder, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 13, color: context.primary),
                  const SizedBox(width: 4),
                  Text(
                    l.venueOwner,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.primary),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Age
          if (member.age != null)
            _InfoRow(
              icon: Icons.cake_rounded,
              label: l.age,
              value: '${member.age} ${l.yearsOld}',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: context.greenTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: context.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: context.textHint)),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// ── Shared avatar widget ──────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double radius;
  const _Avatar({required this.name, this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.greenTint,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      onBackgroundImageError: url != null ? (_, __) {} : null,
      child: url == null
          ? Text(
              initial,
              style: TextStyle(
                color: context.primary,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.75,
              ),
            )
          : null,
    );
  }
}
