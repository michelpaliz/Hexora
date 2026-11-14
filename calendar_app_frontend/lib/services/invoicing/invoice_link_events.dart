typedef InvoiceLinkListener = void Function();

/// Lightweight app-wide signal used to keep invoice and banking views in sync
/// after an invoice is linked to a statement entry.
class InvoiceLinkEvents {
  InvoiceLinkEvents._();

  static final InvoiceLinkEvents instance = InvoiceLinkEvents._();

  final Map<String, Set<InvoiceLinkListener>> _listeners = {};

  VoidCallbackHandle subscribe(String groupId, InvoiceLinkListener listener) {
    final key = groupId.trim();
    if (key.isEmpty) return VoidCallbackHandle._noop();
    final listeners = _listeners.putIfAbsent(key, () => <InvoiceLinkListener>{});
    listeners.add(listener);
    return VoidCallbackHandle(() {
      listeners.remove(listener);
      if (listeners.isEmpty) _listeners.remove(key);
    });
  }

  void emit(String? groupId) {
    final key = groupId?.trim() ?? '';
    if (key.isEmpty) return;
    final listeners = List<InvoiceLinkListener>.from(
      _listeners[key] ?? const <InvoiceLinkListener>{},
    );
    for (final listener in listeners) {
      try {
        listener();
      } catch (_) {
        // A stale view must never turn a successful server-side link into an
        // error for the action that triggered it.
      }
    }
  }
}

class VoidCallbackHandle {
  VoidCallbackHandle(this._dispose);
  VoidCallbackHandle._noop() : _dispose = _empty;

  final void Function() _dispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _dispose();
  }

  static void _empty() {}
}
