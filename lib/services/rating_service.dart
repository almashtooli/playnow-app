import '../core/api_client.dart';
import '../models/rating_models.dart';

class RatingService {
  /// Submit a 1–5 star rating for a completed session.
  /// Backend endpoint: POST /sessions/:id/rate
  Future<void> rateSession(int sessionId, int rating,
      {String? comment}) async {
    final body = <String, dynamic>{'rating': rating};
    if (comment != null && comment.isNotEmpty) body['comment'] = comment;
    await apiClient.post('/sessions/$sessionId/rate', body: body);
  }

  /// Fetch the aggregated rating for a venue.
  /// Backend endpoint: GET /venues/:id/rating
  Future<VenueRating> getVenueRating(int venueId) async {
    final json = await apiClient.get('/venues/$venueId/rating');
    return VenueRating.fromJson(json);
  }

  /// Check if current user has already rated a session.
  /// Backend endpoint: GET /sessions/:id/rating/mine
  Future<bool> hasRated(int sessionId) async {
    try {
      await apiClient.get('/sessions/$sessionId/rating/mine');
      return true;
    } catch (_) {
      return false;
    }
  }
}
