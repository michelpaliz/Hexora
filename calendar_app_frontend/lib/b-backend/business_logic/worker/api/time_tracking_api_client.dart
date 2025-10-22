import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

import 'i_time_tracking_api_client.dart';

class TimeTrackingApiClient implements ITimeTrackingApiClient {
  TimeTrackingApiClient({http.Client? client})
      : _client = client ?? http.Client();
  final http.Client _client;

  String get _root => ApiConstants.baseUrl;
  Map<String, String> _headers(String token, {bool jsonContent = true}) => {
        'Authorization': 'Bearer $token',
        if (jsonContent) 'Content-Type': 'application/json; charset=UTF-8',
      };

  String baseGroupPath(String groupId) => '/groups/$groupId';

  @override
  Future<void> enable(String groupId, String token) async {
    final uri = Uri.parse('$_root${baseGroupPath(groupId)}/enable');
    final res = await _client.post(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to enable time-tracking: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<void> disable(String groupId, String token) async {
    final uri = Uri.parse('$_root${baseGroupPath(groupId)}/disable');
    final res = await _client.post(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception(
          'Failed to disable time-tracking: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<List<Worker>> listWorkers(String groupId, String token) async {
    final uri = Uri.parse('$_root${baseGroupPath(groupId)}/workers');
    final res = await _client.get(uri, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception('Failed to list workers: ${res.statusCode} ${res.body}');
    }
    final raw = jsonDecode(res.body);
    final list = (raw as List).cast<Map<String, dynamic>>();
    return list.map(Worker.fromJson).toList();
  }

  @override
  Future<Worker> createWorker(
      String groupId, Worker worker, String token) async {
    final uri = Uri.parse('$_root${baseGroupPath(groupId)}/workers');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(worker.toCreateJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create worker: ${res.statusCode} ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Worker.fromJson(map);
  }

  // keep your TimeEntry endpoints as you already had them…
  @override
  Future<List<TimeEntry>> listTimeEntries(String groupId, String token,
      {DateTime? from, DateTime? to, String? workerId}) {
    // unchanged from previous snippet
    throw UnimplementedError();
  }

  @override
  Future<TimeEntry> createTimeEntry(
      String groupId, TimeEntry entry, String token) {
    // unchanged from previous snippet
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> exportExcel(String groupId, String token) {
    // unchanged from previous snippet
    throw UnimplementedError();
  }
}
