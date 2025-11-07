class MembersCount {
  final int accepted;
  final int pending;
  final int union;
  final DateTime? updatedAt;

  MembersCount({
    required this.accepted,
    required this.pending,
    required this.union,
    this.updatedAt,
  });

  factory MembersCount.fromJson(Map<String, dynamic> json) => MembersCount(
        accepted: (json['accepted'] ?? 0) as int,
        pending: (json['pending'] ?? 0) as int,
        union: (json['union'] ?? 0) as int,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}
