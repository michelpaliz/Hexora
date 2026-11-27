class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.status,
    required this.visibility,
    required this.placements,
    required this.publishedAt,
    required this.isPinned,
    required this.isRead,
    required this.notificationPriority,
    this.imageUrl,
    this.videoUrl,
    this.expiresAt,
    this.translations,
  });

  final String id;
  final String title;
  final String description;
  final String content;
  final String category;
  final String status;
  final String visibility;
  final List<String> placements;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final String? imageUrl;
  final String? videoUrl;
  final bool isPinned;
  final bool isRead;
  final String notificationPriority;
  final Map<String, dynamic>? translations;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) => value == null
        ? null
        : DateTime.tryParse(value.toString())?.toLocal();
    return Announcement(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      status: (json['status'] ?? 'published').toString(),
      visibility: (json['visibility'] ?? 'public').toString(),
      placements: (json['placements'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      publishedAt: date(json['publishedAt']),
      expiresAt: date(json['expiresAt']),
      imageUrl: json['imageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      isPinned: json['isPinned'] == true,
      isRead: json['isRead'] == true,
      notificationPriority: (json['notificationPriority'] ?? 'none').toString(),
      translations: json['translations'] is Map
          ? Map<String, dynamic>.from(json['translations'] as Map)
          : null,
    );
  }
}

class AnnouncementPage {
  const AnnouncementPage({
    required this.items,
    required this.page,
    required this.pages,
  });
  final List<Announcement> items;
  final int page;
  final int pages;
}
