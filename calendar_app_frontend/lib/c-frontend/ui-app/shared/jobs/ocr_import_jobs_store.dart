import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/jobs/background_job.dart';
import 'package:hexora/b-backend/jobs/jobs_api.dart';

class OcrImportJobsStore extends ChangeNotifier {
  OcrImportJobsStore._();

  static final OcrImportJobsStore instance = OcrImportJobsStore._();

  final JobsApi _api = JobsApi();
  final List<BackgroundJob> _jobs = <BackgroundJob>[];

  Timer? _pollTimer;
  bool _loading = false;
  bool _loadedOnce = false;
  String? _error;

  List<BackgroundJob> get jobs => List.unmodifiable(_jobs);
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;

  List<BackgroundJob> get activeJobs =>
      _jobs.where((job) => job.isActive).toList(growable: false);

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.listJobs(type: 'OCR_IMPORT', limit: 20);
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

  Future<BackgroundJob?> fetchJob(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    try {
      final job = await _api.getJob(trimmed);
      upsert(job);
      return job;
    } catch (_) {
      return _jobs.cast<BackgroundJob?>().firstWhere(
            (job) => job?.id == trimmed,
            orElse: () => null,
          );
    }
  }

  void trackStartedJob({
    required String backgroundJobId,
    required int totalFiles,
  }) {
    final trimmed = backgroundJobId.trim();
    if (trimmed.isEmpty) return;
    upsert(
      BackgroundJob(
        id: trimmed,
        type: 'OCR_IMPORT',
        status: 'pending',
        progress: 0,
        totalItems: totalFiles,
        processedItems: 0,
        failedItems: 0,
        metadata: const {},
        resultSummary: const {},
        errorMessage: null,
        createdAt: DateTime.now(),
        startedAt: null,
        completedAt: null,
        updatedAt: DateTime.now(),
      ),
    );
    unawaited(fetchJob(trimmed));
  }

  void upsert(BackgroundJob job) {
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

  void _replaceJobs(List<BackgroundJob> jobs) {
    _jobs
      ..clear()
      ..addAll(jobs);
    _sortJobs();
  }

  void _sortJobs() {
    _jobs.sort((a, b) {
      final activeCmp = (a.isActive ? 0 : 1).compareTo(b.isActive ? 0 : 1);
      if (activeCmp != 0) return activeCmp;
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
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
      const Duration(seconds: 4),
      (_) => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
