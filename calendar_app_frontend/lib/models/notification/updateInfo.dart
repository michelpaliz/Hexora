class UpdateInfo {
  final String userId;
  final DateTime updatedAt;

  UpdateInfo({
    required this.userId,
    required this.updatedAt,
  });

  // Adding the copyWith method
  UpdateInfo copyWith({
    String? userId,
    DateTime? updatedAt,
  }) {
    return UpdateInfo(
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Method to convert UpdateInfo to a map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Factory method to create UpdateInfo from a map
  factory UpdateInfo.fromMap(Map<String, dynamic> map) {
    return UpdateInfo(
      userId: map['userId'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'UpdateInfo -- > {userId: $userId, updatedAt: $updatedAt}';
  }
}
