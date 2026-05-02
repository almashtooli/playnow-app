import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/chat_models.dart';

class DmChatService extends ChangeNotifier {
  final int friendId;

  DmChatService(this.friendId);

  List<DmMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int _lastId = 0;
  Timer? _pollTimer;

  List<DmMessage> get messages => _messages;
  bool get loading => _loading;
  bool get sending => _sending;

  Future<void> init() async {
    await loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final json = await apiClient.get(
        '/dm/$friendId',
        queryParams: {'after': _lastId.toString(), 'pageSize': '50'},
      );
      final List data = json is List ? json : [];
      if (data.isEmpty) return;
      final newMsgs = data.map((e) => DmMessage.fromJson(e)).toList();
      _messages = [..._messages, ...newMsgs];
      _lastId = _messages.last.id;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMessages() async {
    _loading = true;
    notifyListeners();
    try {
      final json = await apiClient.get(
        '/dm/$friendId',
        queryParams: {'after': '0', 'pageSize': '50'},
      );
      final List data = json is List ? json : [];
      _messages = data.map((e) => DmMessage.fromJson(e)).toList();
      if (_messages.isNotEmpty) _lastId = _messages.last.id;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    _sending = true;
    notifyListeners();
    try {
      final json = await apiClient.post(
        '/dm/$friendId',
        body: {'content': content.trim()},
      );
      final msg = DmMessage.fromJson(json);
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
