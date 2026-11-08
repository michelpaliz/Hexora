import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hexora/models/downloads/download_job.dart';
import 'package:hexora/services/downloads/downloads_api.dart';

class DownloadJobsStore extends ChangeNotifier {
  DownloadJobsStore._();

  static final DownloadJobsStore instance = DownloadJobsStore._();

  final DownloadsApi _api = DownloadsApi();
  final List<DownloadJob> _jobs = <DownloadJob>[];
  final Set<String> _unseenReadyIds = <String>{};

  Timer? _pollTimer;
  DateTime? _nextRefreshAt;
  final Map<String, Future<void>> _refreshes = {};
  String? _groupId;
  bool _loading = false;
  bool _loadedOnce = false;
  String? _error;
  bool _openDownloadsRequested = false;

  List<DownloadJob> get jobs => List.unmodifiable(_jobs);
  int get newReadyCount => _unseenReadyIds.length;

  void markReadySeen() {
    if (_unseenReadyIds.isEmpty) return;
    _unseenReadyIds.clear();
    notifyListeners();
  }

  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get boundGroupId => _groupId;
  String? get error => _error;
  DateTime? get nextRefreshAt => _nextRefreshAt;

  void requestOpenDownloads() {
    _openDownloadsRequested = true;
    notifyListeners();
  }

  bool takeOpenDownloadsRequest() {
    final requested = _openDownloadsRequested;
    _openDownloadsRequested = false;
    return requested;
  }

  Future<void> bindGroup(String groupId) async {
    final normalized = groupId.trim();
    if (normalized.isEmpty) return;
    if (_groupId == normalized) {
      _ensurePolling();
      if (_loadedOnce) return;
      return refresh();
    }
    _pollTimer?.cancel();
    _pollTimer = null;
    _nextRefreshAt = null;
    _groupId = normalized;
    _jobs.clear();
    _unseenReadyIds.clear();
    _loadedOnce = false;
    _loading = false;
    _error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return Future<void>.value();
    final pending = _refreshes[groupId];
    if (pending != null) return pending;
    final refresh = _refreshGroup(groupId);
    _refreshes[groupId] = refresh;
    refresh.whenComplete(() => _refreshes.remove(groupId));
    return refresh;
  }

  Future<void> _refreshGroup(String groupId) async {
    _loading = true;
    notifyListeners();
    try {
      final result =
          await _api.listJobs(groupId: groupId, mine: true, limit: 50);
      if (_groupId != groupId) return;
      _replaceJobs(result);
      _loadedOnce = true;
      _error = null;
    } catch (e) {
      if (_groupId == groupId) {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (_groupId == groupId) {
        _loading = false;
        _ensurePolling();
        notifyListeners();
      }
    }
  }

  Future<DownloadJob?> fetchJob(String id) async {
    if (id.trim().isEmpty) return null;
    try {
      final job = await _api.getJob(id);
      upsert(job);
      return job;
    } catch (_) {
      return _jobs.cast<DownloadJob?>().firstWhere(
            (item) => item?.id == id,
            orElse: () => null,
          );
    }
  }

  Future<DownloadJob> createJob({
    required String groupId,
    required String jobType,
    required String title,
    required String description,
    required Map<String, dynamic> params,
  }) async {
    final job = await _api.createJob(
      groupId: groupId,
      jobType: jobType,
      title: title,
      description: description,
      params: params,
    );
    if (_groupId != groupId) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _nextRefreshAt = null;
      _jobs.clear();
      _unseenReadyIds.clear();
      _groupId = groupId;
    }
    upsert(job);
    _loadedOnce = true;
    _ensurePolling();
    return job;
  }

  void upsert(DownloadJob job) {
    if (_groupId != null && job.groupId != _groupId) return;
    final index = _jobs.indexWhere((item) => item.id == job.id);
    if (job.status == 'ready' &&
        job.canDownload &&
        (index == -1 || _jobs[index].status != 'ready')) {
      _unseenReadyIds.add(job.id);
    }
    if (index == -1) {
      _jobs.add(job);
    } else {
      _jobs[index] = job;
    }
    _sortJobs();
    _ensurePolling();
    notifyListeners();
  }

  void _replaceJobs(List<DownloadJob> jobs) {
    if (_loadedOnce) {
      final previous = {for (final job in _jobs) job.id: job};
      for (final job in jobs) {
        if (job.status == 'ready' &&
            job.canDownload &&
            previous[job.id]?.status != 'ready') {
          _unseenReadyIds.add(job.id);
        }
      }
    }
    final readyIds =
        jobs.where((job) => job.status == 'ready').map((job) => job.id).toSet();
    _unseenReadyIds.removeWhere((id) => !readyIds.contains(id));
    _jobs
      ..clear()
      ..addAll(jobs);
    _sortJobs();
  }

  void _sortJobs() {
    _jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _ensurePolling() {
    final shouldPoll = _jobs.any((job) => job.isActive);
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _nextRefreshAt = null;
      return;
    }
    if (_pollTimer != null) return;
    _nextRefreshAt = DateTime.now().add(const Duration(seconds: 12));
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _nextRefreshAt = DateTime.now().add(const Duration(seconds: 12));
      notifyListeners();
      unawaited(refresh());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
