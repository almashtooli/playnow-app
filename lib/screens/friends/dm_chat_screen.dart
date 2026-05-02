import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_models.dart';
import '../../services/auth_service.dart';
import '../../services/dm_chat_service.dart';
import '../../theme/app_theme.dart';

class DmChatScreen extends StatefulWidget {
  final int friendId;
  final String friendName;
  final String? friendAvatarUrl;

  const DmChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  late final DmChatService _chat;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chat = DmChatService(widget.friendId);
    _chat.addListener(_scrollToBottom);
    _chat.init();
  }

  @override
  void dispose() {
    _chat.removeListener(_scrollToBottom);
    _chat.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chat,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              _Avatar(
                  name: widget.friendName,
                  url: widget.friendAvatarUrl,
                  radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.friendName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _MessageList(scrollController: _scrollController),
            ),
            _InputBar(controller: _inputController, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  const _MessageList({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<DmChatService>(
      builder: (_, chat, __) {
        if (chat.loading) {
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
            final isMe = msg.senderId == myId;
            return _Bubble(message: msg, isMe: isMe);
          },
        );
      },
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final DmMessage message;
  final bool isMe;

  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = _fmt(message.sentAt);
    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 56 : 0,
        right: isMe ? 0 : 56,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  : Border.all(color: context.borderColor, width: 0.5),
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
            child: Text(time,
                style: TextStyle(fontSize: 10, color: context.textHint)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
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
    return Consumer<DmChatService>(
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
              Material(
                color: context.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: chat.sending ? null : onSend,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: chat.sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
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

// ── Shared avatar ─────────────────────────────────────────────────────────────

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
          ? Text(initial,
              style: TextStyle(
                color: context.primary,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.75,
              ))
          : null,
    );
  }
}
