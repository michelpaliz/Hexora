import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// A failure explained for people: what went wrong in plain words, plus the
/// technical detail (status, server message) for support or debugging.
class FriendlyError {
  const FriendlyError({required this.message, this.details});
  final String message;
  final String? details;
}

bool _isEs(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'es';

/// Turns any thrown value into a [FriendlyError]. API exceptions across the
/// app expose `statusCode` and `message`; they are read dynamically so every
/// service's exception type gets the same treatment.
FriendlyError describeError(BuildContext context, Object error) {
  final es = _isEs(context);
  if (error is TimeoutException) {
    return FriendlyError(
      message: es
          ? 'El servidor tardó demasiado en responder. Inténtalo de nuevo.'
          : 'The server took too long to respond. Please try again.',
      details: error.toString(),
    );
  }
  if (error is http.ClientException) {
    return FriendlyError(
      message: es
          ? 'No hay conexión con el servidor. Revisa tu conexión a internet.'
          : 'Could not reach the server. Check your internet connection.',
      details: error.message,
    );
  }
  if (error is FormatException || error is TypeError) {
    return FriendlyError(
      message: es
          ? 'El servidor devolvió una respuesta inesperada.'
          : 'The server returned an unexpected response.',
      details: error.toString(),
    );
  }

  int? status;
  String? serverMessage;
  Map? data;
  try {
    final dynamic e = error;
    status = e.statusCode as int?;
    serverMessage = (e.message as Object?)?.toString().trim();
    data = e.responseData as Map?;
  } catch (_) {}

  if (status != null) {
    final fieldErrors = _fieldErrors(data);
    final base = switch (status) {
      400 || 422 => es
          ? 'Algunos datos no son válidos.'
          : 'Some of the data is not valid.',
      401 => es
          ? 'Tu sesión ha caducado. Vuelve a iniciar sesión.'
          : 'Your session has expired. Please sign in again.',
      403 => es
          ? 'No tienes permiso para realizar esta acción.'
          : 'You don\'t have permission to do this.',
      404 => es
          ? 'El elemento ya no existe o fue eliminado.'
          : 'This item no longer exists.',
      409 => es
          ? 'Hay un conflicto con datos existentes.'
          : 'This conflicts with existing data.',
      >= 500 => es
          ? 'Error del servidor. Inténtalo de nuevo en unos minutos.'
          : 'Server error. Please try again in a few minutes.',
      _ => es ? 'La solicitud no se completó.' : 'The request failed.',
    };
    // The server's own wording is usually the most specific explanation.
    final specific = [
      if (serverMessage != null &&
          serverMessage.isNotEmpty &&
          serverMessage != 'Request failed')
        serverMessage,
      ...fieldErrors,
    ];
    return FriendlyError(
      message: specific.isEmpty ? base : '$base ${specific.join(' · ')}',
      details: 'HTTP $status${serverMessage == null ? '' : ' · $serverMessage'}',
    );
  }

  final text = error.toString().replaceFirst(RegExp(r'^\w*Exception: '), '');
  return FriendlyError(
    message: text.trim().isEmpty
        ? (es ? 'Ha ocurrido un error inesperado.' : 'Something went wrong.')
        : text.trim(),
    details: error.runtimeType.toString(),
  );
}

/// Collects `{errors: {field: msg}}` / `{details: [{message}]}` shapes.
List<String> _fieldErrors(Map? data) {
  if (data == null) return const [];
  final out = <String>[];
  final errors = data['errors'] ?? data['details'];
  if (errors is Map) {
    errors.forEach((key, value) => out.add('$key: $value'));
  } else if (errors is List) {
    for (final item in errors) {
      if (item is Map && item['message'] != null) {
        final path = item['path'] ?? item['field'];
        out.add(path == null ? '${item['message']}' : '$path: ${item['message']}');
      } else if (item != null) {
        out.add(item.toString());
      }
    }
  }
  return out;
}
