import 'session_models.dart';

class VenuePhoto {
  final int id;
  final int venueId;
  final String url;
  final String? caption;
  final String? captionAr;
  final int sortOrder;
  final bool isCover;
  final DateTime createdAt;

  const VenuePhoto({
    required this.id,
    required this.venueId,
    required this.url,
    this.caption,
    this.captionAr,
    required this.sortOrder,
    required this.isCover,
    required this.createdAt,
  });

  factory VenuePhoto.fromJson(Map<String, dynamic> json) => VenuePhoto(
        id: json['id'],
        venueId: json['venueId'] ?? 0,
        url: json['url'] ?? '',
        caption: json['caption'],
        captionAr: json['captionAr'],
        sortOrder: json['sortOrder'] ?? 0,
        isCover: json['isCover'] ?? false,
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
      );
}

class VenueVideo {
  final int id;
  final int venueId;
  final String url;
  final String? thumbnailUrl;
  final String? title;
  final String? titleAr;
  final DateTime createdAt;

  const VenueVideo({
    required this.id,
    required this.venueId,
    required this.url,
    this.thumbnailUrl,
    this.title,
    this.titleAr,
    required this.createdAt,
  });

  factory VenueVideo.fromJson(Map<String, dynamic> json) => VenueVideo(
        id: json['id'],
        venueId: json['venueId'] ?? 0,
        url: json['url'] ?? '',
        thumbnailUrl: json['thumbnailUrl'],
        title: json['title'],
        titleAr: json['titleAr'],
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
      );
}

class Venue {
  final int id;
  final String name;
  final String? nameAr;
  final String city;
  final String? cityAr;
  final String? area;
  final String? address;
  final String? addressAr;
  final String? descriptionAr;
  final String? phone;
  final bool isActive;
  final String? imageUrl;
  final String? description;
  final double? latitude;
  final double? longitude;
  final List<Pitch>? pitches;
  final List<VenuePhoto>? photos;
  final List<VenueVideo>? videos;

  const Venue({
    required this.id,
    required this.name,
    this.nameAr,
    required this.city,
    this.cityAr,
    this.area,
    this.address,
    this.addressAr,
    this.descriptionAr,
    this.phone,
    required this.isActive,
    this.imageUrl,
    this.description,
    this.latitude,
    this.longitude,
    this.pitches,
    this.photos,
    this.videos,
  });

  String localizedName(String locale) =>
      (locale == 'ar' && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  String localizedCity(String locale) =>
      (locale == 'ar' && cityAr != null && cityAr!.isNotEmpty) ? cityAr! : city;

  String? localizedAddress(String locale) =>
      (locale == 'ar' && addressAr != null && addressAr!.isNotEmpty) ? addressAr : address;

  String? localizedDescription(String locale) =>
      (locale == 'ar' && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr
          : description;

  VenuePhoto? get coverPhoto {
    if (photos == null || photos!.isEmpty) return null;
    return photos!.firstWhere((p) => p.isCover, orElse: () => photos!.first);
  }

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'],
        name: json['name'] ?? '',
        nameAr: json['nameAr'],
        city: json['city'] ?? '',
        cityAr: json['cityAr'],
        area: json['area'],
        address: json['address'],
        addressAr: json['addressAr'],
        descriptionAr: json['descriptionAr'],
        phone: json['phone'],
        isActive: json['isActive'] ?? true,
        imageUrl: json['imageUrl'],
        description: json['description'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        pitches: json['pitches'] != null
            ? (json['pitches'] as List).map((p) => Pitch.fromJson(p)).toList()
            : null,
        photos: json['photos'] != null
            ? (json['photos'] as List).map((p) => VenuePhoto.fromJson(p)).toList()
            : null,
        videos: json['videos'] != null
            ? (json['videos'] as List).map((v) => VenueVideo.fromJson(v)).toList()
            : null,
      );
}
