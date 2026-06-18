import 'package:hexora/a-models/group_model/client/client_contract.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

const List<String> kClientContractTypeValues = <String>[
  'service',
  'maintenance',
  'rental',
  'nda',
  'custom',
];

const List<String> kClientContractStatusValues = <String>[
  'draft',
  'active',
  'expired',
  'terminated',
  'archived',
];

String clientContractTypeLabel(AppLocalizations l, String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'service':
      return l.clientContractTypeService;
    case 'maintenance':
      return l.clientContractTypeMaintenance;
    case 'rental':
      return l.clientContractTypeRental;
    case 'nda':
      return l.clientContractTypeNda;
    case 'custom':
      return l.clientContractTypeCustom;
    default:
      final raw = (value ?? '').trim();
      return raw.isEmpty ? l.clientContractTypeLabel : raw;
  }
}

String clientContractStatusLabel(AppLocalizations l, String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'draft':
      return l.statusDraft;
    case 'active':
      return l.statusActive;
    case 'expired':
      return l.clientContractStatusExpired;
    case 'terminated':
      return l.clientContractStatusTerminated;
    case 'archived':
      return l.clientContractStatusArchived;
    default:
      final raw = (value ?? '').trim();
      return raw.isEmpty ? l.statusLabel : raw;
  }
}

String formatClientContractDate(AppLocalizations l, DateTime? value) {
  if (value == null) return '—';
  return DateFormat.yMMMd(l.localeName).format(value.toLocal());
}

String formatClientContractDateTime(AppLocalizations l, DateTime? value) {
  if (value == null) return '—';
  return DateFormat.yMMMd(l.localeName).add_Hm().format(value.toLocal());
}

String formatClientContractSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = <String>['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  final digits = size >= 10 || unit == 0 ? 0 : 1;
  return '${size.toStringAsFixed(digits)} ${units[unit]}';
}

List<ClientContract> sortClientContracts(Iterable<ClientContract> source) {
  final contracts = source.toList(growable: false);
  contracts.sort((a, b) {
    if (a.isCurrent != b.isCurrent) {
      return a.isCurrent ? -1 : 1;
    }
    final aStamp = a.createdAt ?? a.updatedAt;
    final bStamp = b.createdAt ?? b.updatedAt;
    if (aStamp == null && bStamp == null) return 0;
    if (aStamp == null) return 1;
    if (bStamp == null) return -1;
    return bStamp.compareTo(aStamp);
  });
  return contracts;
}

bool isClientContractExpired(
  ClientContract contract, {
  DateTime? now,
}) {
  final endDate = contract.endDate;
  if (endDate == null) return false;
  final today = _stripTime(now ?? DateTime.now());
  return _stripTime(endDate).isBefore(today);
}

bool isClientContractExpiringSoon(
  ClientContract contract, {
  DateTime? now,
  int days = 30,
}) {
  final endDate = contract.endDate;
  if (endDate == null) return false;
  final today = _stripTime(now ?? DateTime.now());
  final limit = today.add(Duration(days: days));
  final normalizedEnd = _stripTime(endDate);
  return !normalizedEnd.isBefore(today) && !normalizedEnd.isAfter(limit);
}

List<String> parseClientContractTags(String raw) {
  return raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

String? clientContractDateForApi(DateTime? value) {
  if (value == null) return null;
  return DateFormat('yyyy-MM-dd').format(value);
}

DateTime _stripTime(DateTime value) =>
    DateTime(value.year, value.month, value.day);
