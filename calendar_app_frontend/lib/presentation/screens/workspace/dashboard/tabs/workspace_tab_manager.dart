import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workspace_tab.dart';

typedef WorkspaceTabResolver = WorkspaceTab? Function(
  WorkspaceTabSnapshot snapshot,
);
typedef WorkspaceTabSaveHandler = Future<bool> Function();

/// Single source of truth for desktop workspace tabs.
class WorkspaceTabManager extends ChangeNotifier {
  WorkspaceTabManager({required this.businessId});

  final String businessId;
  final List<WorkspaceTab> _tabs = <WorkspaceTab>[];
  final List<WorkspaceTabIdentity> _recentlyUsed = <WorkspaceTabIdentity>[];
  final Set<WorkspaceTabIdentity> _dirtyTabs = <WorkspaceTabIdentity>{};
  final Map<WorkspaceTabIdentity, WorkspaceTabSaveHandler> _saveHandlers =
      <WorkspaceTabIdentity, WorkspaceTabSaveHandler>{};

  WorkspaceTabIdentity? _activeIdentity;
  String? _userId;
  int _persistenceRevision = 0;
  bool _persistScheduled = false;

  List<WorkspaceTab> get tabs => List.unmodifiable(_tabs);
  WorkspaceTabIdentity? get activeIdentity => _activeIdentity;
  WorkspaceTab? get activeTab => _find(_activeIdentity);

  WorkspaceTab openOrActivateTab(WorkspaceTab tab) {
    final existing = _find(tab.identity);
    if (existing != null) {
      final index = _tabs.indexOf(existing);
      final resolved = existing.copyWith(
        title: tab.title,
        arguments: tab.arguments,
      );
      _tabs[index] = resolved;
      _activate(existing.identity);
      _changed();
      return resolved;
    }
    _tabs.add(tab);
    _activate(tab.identity);
    _changed();
    return tab;
  }

  void activateTab(WorkspaceTabIdentity identity) {
    if (_activeIdentity == identity || _find(identity) == null) return;
    _activate(identity);
    _changed();
  }

  void closeTab(WorkspaceTabIdentity identity) {
    final index = _tabs.indexWhere((tab) => tab.identity == identity);
    if (index < 0) return;
    _tabs.removeAt(index);
    _recentlyUsed.remove(identity);
    _dirtyTabs.remove(identity);
    _saveHandlers.remove(identity);

    if (_activeIdentity == identity) {
      _activeIdentity = null;
      for (final candidate in _recentlyUsed.reversed) {
        if (_find(candidate) != null) {
          _activeIdentity = candidate;
          break;
        }
      }
      _activeIdentity ??= _tabs.isEmpty
          ? null
          : _tabs[index.clamp(0, _tabs.length - 1)].identity;
      final active = _activeIdentity;
      if (active != null) _touch(active);
    }
    _changed();
  }

  void closeOtherTabs(WorkspaceTabIdentity identity) {
    final keep = _find(identity);
    if (keep == null) return;
    _tabs.removeWhere((tab) => tab.identity != identity);
    _recentlyUsed
      ..clear()
      ..add(identity);
    _dirtyTabs.removeWhere((candidate) => candidate != identity);
    _saveHandlers.removeWhere((candidate, _) => candidate != identity);
    _activeIdentity = identity;
    _changed();
  }

  void updateTabTitle(WorkspaceTabIdentity identity, String title) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final index = _tabs.indexWhere((tab) => tab.identity == identity);
    if (index < 0 || _tabs[index].title == cleanTitle) return;
    _tabs[index] = _tabs[index].copyWith(title: cleanTitle);
    _changed();
  }

  bool isDirty(WorkspaceTabIdentity identity) => _dirtyTabs.contains(identity);

  void setDirty(
    WorkspaceTabIdentity identity, {
    required bool dirty,
    WorkspaceTabSaveHandler? onSave,
  }) {
    if (_find(identity) == null) return;
    final wasDirty = _dirtyTabs.contains(identity);
    final previousHandler = _saveHandlers[identity];
    dirty ? _dirtyTabs.add(identity) : _dirtyTabs.remove(identity);
    if (onSave != null) {
      _saveHandlers[identity] = onSave;
    } else if (!dirty) {
      _saveHandlers.remove(identity);
    }
    if (wasDirty == dirty &&
        (onSave == null || identical(previousHandler, onSave))) {
      return;
    }
    notifyListeners();
  }

  bool canSave(WorkspaceTabIdentity identity) =>
      _saveHandlers.containsKey(identity);

  Future<bool> save(WorkspaceTabIdentity identity) async {
    final handler = _saveHandlers[identity];
    if (handler == null) return false;
    final saved = await handler();
    if (saved) setDirty(identity, dirty: false);
    return saved;
  }

  Future<void> configureSession(String userId) async {
    _userId = userId;
  }

  Future<bool> restore({required WorkspaceTabResolver resolver}) async {
    final key = _storageKey;
    if (key == null) return false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(key);
      if (encoded == null || encoded.isEmpty) return false;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return false;
      final rawTabs = decoded['tabs'];
      if (rawTabs is! List) return false;

      final restored = <WorkspaceTab>[];
      for (final raw in rawTabs) {
        if (raw is! Map) continue;
        final snapshot = WorkspaceTabSnapshot.fromJson(
          Map<String, dynamic>.from(raw),
        );
        if (snapshot.identity.isEmpty || snapshot.section.isEmpty) continue;
        final tab = resolver(snapshot);
        if (tab != null &&
            !restored.any((item) => item.identity == tab.identity)) {
          restored.add(tab);
        }
      }
      if (restored.isEmpty) return false;

      _tabs
        ..clear()
        ..addAll(restored);
      _recentlyUsed
        ..clear()
        ..addAll(restored.map((tab) => tab.identity));
      final activeValue = decoded['activeIdentity'] as String?;
      final requested =
          activeValue == null ? null : WorkspaceTabIdentity(activeValue);
      _activeIdentity = requested != null && _find(requested) != null
          ? requested
          : restored.last.identity;
      _touch(_activeIdentity!);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  WorkspaceTab? _find(WorkspaceTabIdentity? identity) {
    if (identity == null) return null;
    for (final tab in _tabs) {
      if (tab.identity == identity) return tab;
    }
    return null;
  }

  void _activate(WorkspaceTabIdentity identity) {
    _activeIdentity = identity;
    _touch(identity);
  }

  void _touch(WorkspaceTabIdentity identity) {
    _recentlyUsed
      ..remove(identity)
      ..add(identity);
  }

  void _changed() {
    notifyListeners();
    ++_persistenceRevision;
    if (_persistScheduled) return;
    _persistScheduled = true;
    scheduleMicrotask(() {
      _persistScheduled = false;
      unawaited(_persist(_persistenceRevision));
    });
  }

  String? get _storageKey {
    final userId = _userId;
    if (userId == null || userId.isEmpty || businessId.isEmpty) return null;
    return 'hexora.workspace_tabs.$userId.$businessId';
  }

  Future<void> _persist(int revision) async {
    final key = _storageKey;
    if (key == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (revision != _persistenceRevision) return;
      await preferences.setString(
        key,
        jsonEncode(<String, Object?>{
          'activeIdentity': _activeIdentity?.value,
          'tabs': _tabs.map((tab) => tab.toSnapshot().toJson()).toList(),
        }),
      );
    } catch (_) {
      // Navigation must keep working when browser storage is unavailable.
    }
  }
}
