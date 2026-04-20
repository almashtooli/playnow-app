import '../core/api_client.dart';
import '../models/venue_models.dart';

class PagedResult<T> {
  final List<T> data;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasMore => page * pageSize < totalCount;

  PagedResult({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });
}

class VenueService {
  Future<PagedResult<Venue>> getVenuesPaged({
    String? city,
    String? q,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (city != null) params['city'] = city;
    if (q != null) params['q'] = q;

    final json = await apiClient.get('/venues', queryParams: params);
    final List data = json is List ? json : (json['data'] ?? []);
    return PagedResult(
      data: data.map((e) => Venue.fromJson(e)).toList(),
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? pageSize,
      totalCount: json['totalCount'] ?? data.length,
    );
  }

  Future<List<Venue>> getVenues({String? city, String? q}) async {
    final result = await getVenuesPaged(city: city, q: q, pageSize: 50);
    return result.data;
  }

  Future<Venue> getVenueById(int id) async {
    final json = await apiClient.get('/venues/$id');
    return Venue.fromJson(json);
  }

  Future<List<Venue>> getAllVenuesAdmin() async {
    final json = await apiClient.get(
      '/venues',
      queryParams: {'pageSize': '100'},
    );
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => Venue.fromJson(e)).toList();
  }

  Future<void> activateVenue(int id) async {
    await apiClient.post('/venues/$id/activate');
  }

  Future<void> deactivateVenue(int id) async {
    await apiClient.post('/venues/$id/deactivate');
  }

  Future<List<Venue>> getMyVenues() async {
    final json = await apiClient.get('/venues/my');
    final List data = json is List ? json : (json['data'] ?? []);
    return data.map((e) => Venue.fromJson(e)).toList();
  }

  Future<void> createVenue({
    required String name,
    String? city,
    String? address,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await apiClient.post(
      '/venues',
      body: {
        'name': name,
        'city': city,
        'address': address,
        'description': description,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }
}
