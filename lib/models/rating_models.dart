class VenueRating {
  final double averageRating;
  final int totalRatings;

  VenueRating({required this.averageRating, required this.totalRatings});

  factory VenueRating.fromJson(Map<String, dynamic> json) => VenueRating(
        averageRating: (json['averageRating'] ?? 0).toDouble(),
        totalRatings: json['totalRatings'] ?? 0,
      );
}

class SessionRating {
  final int id;
  final int sessionId;
  final int userId;
  final int rating; // 1–5
  final String? comment;
  final DateTime createdAt;

  SessionRating({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory SessionRating.fromJson(Map<String, dynamic> json) => SessionRating(
        id: json['id'],
        sessionId: json['sessionId'],
        userId: json['userId'],
        rating: json['rating'],
        comment: json['comment'],
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
      );
}
