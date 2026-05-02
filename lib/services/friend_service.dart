import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/friend_models.dart';

/// Manages friend relationships.
///
/// Required backend endpoints:
///   GET    /friends                     → List<Friend>
///   GET    /friends/requests/incoming   → List<FriendRequest>
///   POST   /friends/requests            → body: {targetUserId}
///   POST   /friends/requests/:id/accept
///   POST   /friends/requests/:id/reject
///   DELETE /friends/:userId
///   GET    /users/search?q=...          → List<PublicUser>
///   POST   /sessions/:id/invite         → body: {userIds: [...]}
class FriendService extends ChangeNotifier {
  List<Friend> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  bool _loading = false;
  String? _error;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get incomingRequests =>
      List.unmodifiable(_incomingRequests);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await apiClient.get('/friends');
      final List data = json is List ? json : (json['data'] ?? []);
      _friends = data.map((e) => Friend.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint('FriendService.loadFriends error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadIncomingRequests() async {
    try {
      final json = await apiClient.get('/friends/requests/incoming');
      final List data = json is List ? json : (json['data'] ?? []);
      _incomingRequests =
          data.map((e) => FriendRequest.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('FriendService.loadIncomingRequests error: $e');
    }
  }

  Future<List<PublicUser>> getRandomUsers({int limit = 10}) async {
    final json = await apiClient.get('/users/random',
        queryParams: {'limit': limit.toString()});
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => PublicUser.fromJson(e)).toList();
  }

  Future<List<PublicUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final json = await apiClient.get('/users/search',
        queryParams: {'q': query.trim()});
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => PublicUser.fromJson(e)).toList();
  }

  Future<void> sendFriendRequest(int targetUserId) async {
    await apiClient.post('/friends/requests',
        body: {'receiverId': targetUserId});
    notifyListeners();
  }

  Future<void> acceptRequest(int requestId) async {
    await apiClient.post('/friends/requests/$requestId/accept');
    _incomingRequests.removeWhere((r) => r.id == requestId);
    // Reload friends list to include the new friend
    await loadFriends();
  }

  Future<void> rejectRequest(int requestId) async {
    await apiClient.post('/friends/requests/$requestId/reject');
    _incomingRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  Future<void> removeFriend(int friendUserId) async {
    await apiClient.delete('/friends/$friendUserId');
    _friends.removeWhere((f) => f.userId == friendUserId);
    notifyListeners();
  }

  /// Send session invitations to a list of friends.
  Future<void> inviteToSession(int sessionId, List<int> friendUserIds) async {
    await apiClient.post('/sessions/$sessionId/invite',
        body: {'userIds': friendUserIds});
  }
}
