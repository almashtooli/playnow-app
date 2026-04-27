import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/session_models.dart';
import 'venue_service.dart'; // for PagedResult

class SessionService {
  // Bumped after any join/cancel so listeners (e.g. MyBookingsScreen) can refresh.
  static final refreshBookings = ValueNotifier<int>(0);
  Future<PagedResult<Session>> getSessionsPaged({
    int? venueId,
    bool availableOnly = false,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (venueId != null) params['venueId'] = venueId.toString();
    if (availableOnly) params['availableOnly'] = 'true';
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();

    final json = await apiClient.get('/sessions', queryParams: params);
    final List data = json is List ? json : (json['data'] ?? []);
    return PagedResult(
      data: data.map((e) => Session.fromJson(e)).toList(),
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? pageSize,
      totalCount: json['totalCount'] ?? data.length,
    );
  }

  // Keep simple version for dashboard use
  Future<List<Session>> getSessions({
    int? venueId,
    bool availableOnly = false,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await getSessionsPaged(
      venueId: venueId,
      availableOnly: availableOnly,
      from: from,
      to: to,
      pageSize: 50,
    );
    return result.data;
  }

  Future<List<Session>> getMyBookings() async {
    final json = await apiClient.get('/sessions/my-bookings');
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => Session.fromBookingJson(e)).toList();
  }

  Future<Session> getSession(int id) async {
    final json = await apiClient.get('/sessions/$id');
    return Session.fromJson(json);
  }

  Future<void> joinSession(int sessionId, {String? position, int seats = 1}) async {
    final body = <String, dynamic>{'seats': seats};
    if (position != null) body['position'] = position;
    await apiClient.post('/sessions/$sessionId/join', body: body);
    refreshBookings.value++;
  }

  Future<void> cancelJoin(int sessionId) async {
    await apiClient.post('/sessions/$sessionId/cancel-join');
    refreshBookings.value++;
  }
}
