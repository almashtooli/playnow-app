import '../core/api_client.dart';
import '../models/match_booking_models.dart';

class MatchBookingService {
  Future<MatchBooking> create({
    required int pitchId,
    required int teamsCount,
    required int teamSize,
    required DateTime startsAt,
    required DateTime endsAt,
    String? notes,
  }) async {
    final json = await apiClient.post('/match-bookings', body: {
      'pitchId': pitchId,
      'teamsCount': teamsCount,
      'teamSize': teamSize,
      'requestedStartsAt': startsAt.toUtc().toIso8601String(),
      'requestedEndsAt': endsAt.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    // server returns {id, status} on create — fetch full object
    return await getById(json['id']);
  }

  Future<MatchBooking> getById(int id) async {
    final json = await apiClient.get('/match-bookings/$id');
    return MatchBooking.fromJson(json);
  }

  Future<List<MatchBooking>> getMyBookings() async {
    final json = await apiClient.get('/match-bookings/my');
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => MatchBooking.fromJson(e)).toList();
  }

  // Venue owner: get pending/rescheduled requests
  Future<List<MatchBooking>> getVenueRequests({int? venueId, String? status}) async {
    final params = <String, String>{};
    if (venueId != null) params['venueId'] = venueId.toString();
    if (status != null) params['status'] = status;
    final json = await apiClient.get('/match-bookings/venue', queryParams: params);
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => MatchBooking.fromJson(e)).toList();
  }

  Future<void> approve(int id, {double? pricePerPlayer}) async =>
      await apiClient.post('/match-bookings/$id/approve', body: {
        if (pricePerPlayer != null) 'pricePerPlayer': pricePerPlayer,
      });

  Future<void> cancel(int id) async =>
      await apiClient.post('/match-bookings/$id/cancel');

  Future<void> reschedule(
    int id,
    DateTime startsAt,
    DateTime endsAt, {
    double? pricePerPlayer,
  }) async =>
      await apiClient.post('/match-bookings/$id/reschedule', body: {
        'proposedStartsAt': startsAt.toUtc().toIso8601String(),
        'proposedEndsAt': endsAt.toUtc().toIso8601String(),
        if (pricePerPlayer != null) 'pricePerPlayer': pricePerPlayer,
      });

  Future<void> acceptReschedule(int id) async =>
      await apiClient.post('/match-bookings/$id/accept-reschedule');

  Future<void> rejectReschedule(int id) async =>
      await apiClient.post('/match-bookings/$id/reject-reschedule');
}
