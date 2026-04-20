import '../core/api_client.dart';
import '../models/dashboard_models.dart';
import '../models/session_models.dart';
import '../models/venue_models.dart';

class DashboardService {
  Future<List<Venue>> getMyVenues() async {
    final json = await apiClient.get('/venues/my');
    // /venues/my returns a plain array, not paginated
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => Venue.fromJson(e)).toList();
  }

  Future<List<Session>> getVenueSessions(int venueId) async {
    final json = await apiClient.get(
      '/sessions',
      queryParams: {'venueId': venueId.toString()},
    );
    // /sessions returns paginated { data: [...], totalCount, page, pageSize }
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => Session.fromJson(e)).toList();
  }

  Future<List<SessionPlayer>> getSessionPlayers(int sessionId) async {
    final json = await apiClient.get('/sessions/$sessionId/players');
    // /sessions/{id}/players returns a plain array
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => SessionPlayer.fromJson(e)).toList();
  }

  Future<void> createSession({
    required int pitchId,
    required String startsAt,
    required String endsAt,
    required int maxPlayers,
    required double pricePerPlayer,
  }) async {
    await apiClient.post(
      '/sessions',
      body: {
        'pitchId': pitchId,
        'startsAt': startsAt,
        'endsAt': endsAt,
        'maxPlayers': maxPlayers,
        'pricePerPlayer': pricePerPlayer,
      },
    );
  }

  Future<void> cancelSession(int sessionId, {String? reason}) async {
    await apiClient.post(
      '/sessions/$sessionId/cancel',
      body: {'reason': reason ?? ''},
    );
  }

  Future<void> checkIn(int sessionId, int userId) async {
    await apiClient.post('/sessions/$sessionId/checkin/$userId');
  }
}
