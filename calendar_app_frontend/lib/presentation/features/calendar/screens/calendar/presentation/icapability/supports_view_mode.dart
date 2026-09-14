// lib/presentation/calendar/screens/calendar/presentation/view_adapter/adapter_flow/adapter/supports_view_mode.dart
abstract class SupportsViewMode {
  /// mode: 'day' | 'week' | 'month' | 'agenda'
  void setViewMode(String mode);

  /// Optional: read the current mode
  String get currentViewMode;
}
