import 'package:flutter/material.dart';

/// Stable identity for a logical workspace destination. Titles are deliberately
/// excluded because they may change after a record is saved.
@immutable
class WorkspaceTabIdentity {
  const WorkspaceTabIdentity(this.value) : assert(value != '');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is WorkspaceTabIdentity && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

@immutable
class WorkspaceTab {
  const WorkspaceTab({
    required this.identity,
    required this.section,
    required this.title,
    required this.icon,
    this.arguments = const <String, String>{},
  });

  final WorkspaceTabIdentity identity;
  final String section;
  final String title;
  final IconData icon;
  final Map<String, String> arguments;

  WorkspaceTab copyWith({
    String? title,
    Map<String, String>? arguments,
  }) =>
      WorkspaceTab(
        identity: identity,
        section: section,
        title: title ?? this.title,
        icon: icon,
        arguments: arguments ?? this.arguments,
      );

  WorkspaceTabSnapshot toSnapshot() => WorkspaceTabSnapshot(
        identity: identity.value,
        section: section,
        title: title,
        arguments: arguments,
      );
}

/// Safe, serializable metadata used for session restoration. Widget state and
/// unsaved form values are intentionally never persisted.
@immutable
class WorkspaceTabSnapshot {
  const WorkspaceTabSnapshot({
    required this.identity,
    required this.section,
    required this.title,
    this.arguments = const <String, String>{},
  });

  final String identity;
  final String section;
  final String title;
  final Map<String, String> arguments;

  Map<String, Object> toJson() => <String, Object>{
        'identity': identity,
        'section': section,
        'title': title,
        'arguments': arguments,
      };

  factory WorkspaceTabSnapshot.fromJson(Map<String, dynamic> json) {
    final rawArguments = json['arguments'];
    return WorkspaceTabSnapshot(
      identity: json['identity'] as String? ?? '',
      section: json['section'] as String? ?? '',
      title: json['title'] as String? ?? '',
      arguments: rawArguments is Map
          ? rawArguments.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
    );
  }
}
