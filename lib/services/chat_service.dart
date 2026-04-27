import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/chat_models.dart';

class ChatService extends ChangeNotifier {
  final int sessionId;

  ChatService(this.sessionId);

  List<ChatMessage> _messages = [];
  List<ChatMember> _members = [];
  bool _loadingMessages = true;
  bool _loadingMembers = true;
  bool _sending = false;
  int _lastId = 0;
  Timer? _pollTimer;

  List<ChatMessage> get messages => _messages;
  List<ChatMember> get members => _members;
  bool get loadingMessages => _loadingMessages;
  bool get loadingMembers => _loadingMembers;
  bool get sending => _sending;

  Future<void> init() async {
    await Future.wait([loadMessages(), loadMembers()]);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final json = await apiClient.get(
        '/sessions/$sessionId/chat',
        queryParams: {'after': _lastId.toString(), 'pageSize': '50'},
      );
      final List data = json is List ? json : [];
      if (data.isEmpty) return;
      final newMsgs = data.map((e) => ChatMessage.fromJson(e)).toList();
      _messages = [..._messages, ...newMsgs];
      _lastId = _messages.last.id;
      notifyListeners();
    } catch (_) {
      // silent — keeps showing stale messages rather than erroring
    }
  }

  Future<void> loadMessages() async {
    _loadingMessages = true;
    notifyListeners();
    try {
      final json = await apiClient.get(
        '/sessions/$sessionId/chat',
        queryParams: {'after': '0', 'pageSize': '50'},
      );
      final List data = json is List ? json : [];
      _messages = data.map((e) => ChatMessage.fromJson(e)).toList();
      if (_messages.isNotEmpty) _lastId = _messages.last.id;
    } on ApiException {
      rethrow;
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> loadMembers() async {
    _loadingMembers = true;
    notifyListeners();
    try {
      final json = await apiClient.get('/sessions/$sessionId/chat/members');
      final List data = json is List ? json : [];
      _members = data.map((e) => ChatMember.fromJson(e)).toList();
    } finally {
      _loadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    _sending = true;
    notifyListeners();
    try {
      final json = await apiClient.post(
        '/sessions/$sessionId/chat',
        body: {'content': content.trim()},
      );
      final msg = ChatMessage.fromJson(json);
      _messages = [..._messages, msg];
      _lastId = msg.id;
      notifyListeners();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
