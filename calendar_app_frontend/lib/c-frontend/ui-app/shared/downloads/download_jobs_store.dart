import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/b-backend/downloads/downloads_api.dart';

class DownloadJobsStore extends ChangeNotifier {
  DownloadJobsStore._();

  static final DownloadJobsStore instance = DownloadJobsStore._();

  final DownloadsApi _api = DownloadsApi();
  final List<DownloadJob> _jobs = <DownloadJob>[];

  Timer? _pollTimer;
  String? _groupId;
  bool _loading = false;
  bool _loadedOnce = false;
  String? _error;

  List<DownloadJob> get jobs => List.unmodifiable(_jobs);
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;

  Future<void> bindGroup(String groupId) async {
    final normalized = groupId.trim();
    if (normalized.isEmpty) return;
    if (_groupId == normalized && _loadedOnce) {
      _ensurePolling();
      return;
    }
    _groupId = normalized;
    _jobs.clear();
    _loadedOnce = false;
    _error = null;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    final groupId = _groupId;
    if (groupId == null || groupId.isEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.listJobs(groupId: groupId, mine: true, limit: 50);
      _replaceJobs(result);
      _loadedOnce = true;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      _ensurePolling();
      notifyListeners();
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
    _groupId = groupId;
    upsert(job);
    _loadedOnce = true;
    _ensurePolling();
    return job;
  }

  void upsert(DownloadJob job) {
    final index = _jobs.indexWhere((item) => item.id == job.id);
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
    _jobs
      ..clear()
      ..addAll(jobs);
    _sortJobs();
  }

  void _sortJobs() {
    _jobs.sort((a, b) {
      final aActive = a.isActive ? 0 : 1;
      final bActive = b.isActive ? 0 : 1;
      final activeCmp = aActive.compareTo(bActive);
      if (activeCmp != 0) return activeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void _ensurePolling() {
    final shouldPoll = _jobs.any((job) => job.isActive);
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
