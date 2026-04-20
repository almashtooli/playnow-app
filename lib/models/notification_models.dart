class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] ?? '',
        referenceId: json['referenceId'],
        referenceType: json['referenceType'],
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
      );
}
