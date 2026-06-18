import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

extension NotificationLocalization on NotificationUser {
  String getLocalizedTitle(AppLocalizations loc) {
    final isEs = loc.localeName.toLowerCase().startsWith('es');
    switch (titleKey) {
      case 'notification.bankExpensesDetected.title':
      case 'notification.bank.expenses.detected.title':
      case 'notification.suspectExpenses.detected.title':
        return loc.notificationBankExpensesDetectedTitle;
      case 'notification.groupCreation.title':
        return loc.notificationGroupCreationTitle;
      case 'notification.joinedGroup.title':
        return loc.notificationJoinedGroupTitle;
      case 'notification.invitation.title':
        return loc.notificationInvitationTitle;
      case 'notification.invitationDenied.title':
        return loc.notificationInvitationDeniedTitle;
      case 'notification.userAccepted.title':
        return loc.notificationUserAcceptedTitle;
      case 'notification.groupEdited.title':
        return loc.notificationGroupEditedTitle;
      case 'notification.groupDeleted.title':
        return loc.notificationGroupDeletedTitle;
      case 'notification.userRemoved.title':
        return loc.notificationUserRemovedTitle;
      case 'notification.adminUserRemoved.title':
        return loc.notificationAdminUserRemovedTitle;
      case 'notification.userLeft.title':
        return loc.notificationUserLeftTitle;
      case 'notification.groupUpdate.title':
        return loc.notificationGroupUpdateTitle;
      case 'notification.groupDeletedAll.title':
        return loc.notificationGroupDeletedAllTitle;

      //Reminder notifications
      case 'notification.event.started.title':
        return loc.notificationEventStartedTitle;

      // 🔹 Event-related titles
      case 'notification.event.reminder.title':
        return loc.notificationEventReminderTitle;
      case 'notification.event.created.title':
        return loc.notificationEventCreatedTitle;
      case 'notification.event.updated.title':
        return loc.notificationEventUpdatedTitle;
      case 'notification.event.deleted.title':
        return loc.notificationEventDeletedTitle;
      case 'notification.recurrenceAdded.title':
        return loc.notificationRecurrenceAddedTitle;
      case 'notification.eventMarkedDone.title':
        return loc.notificationEventMarkedDoneTitle;
      case 'notification.eventReopened.title':
        return loc.notificationEventReopenedTitle;
      case 'notification.event.concurrentCreated.title':
        return isEs ? 'Conflicto de evento detectado' : 'Concurrent event detected';
      case 'notification.invoice.issued.title':
        return isEs ? 'Factura emitida' : 'Invoice issued';
      case 'notification.receipt.issued.title':
        return isEs ? 'Recibo emitido' : 'Receipt issued';
      case 'notification.presupuesto.issued.title':
        return isEs ? 'Presupuesto emitido' : 'Presupuesto issued';

      case 'notification.recurringInvoice.draftCreated.title':
      case 'notification.recurring.invoice.draft.created.title':
      case 'notification.recurringDraftInvoice.created.title':
        return loc.notificationRecurringDraftInvoiceCreatedTitle;

      default:
        if (_isBankExpensesDetectedNotification(this)) {
          return loc.notificationBankExpensesDetectedTitle;
        }
        if (_isRecurringDraftInvoiceNotification(this)) {
          return loc.notificationRecurringDraftInvoiceCreatedTitle;
        }
        return fallbackTitle;
    }
  }

  String getLocalizedMessage(AppLocalizations loc) {
    final isEs = loc.localeName.toLowerCase().startsWith('es');
    switch (messageKey) {
      case 'notification.bankExpensesDetected.message':
      case 'notification.bank.expenses.detected.message':
      case 'notification.suspectExpenses.detected.message':
        return _localizedBankExpensesDetectedMessage(loc) ?? fallbackMessage;
      case 'notification.groupCreation.message':
        return loc.notificationGroupCreationMessage(args['groupName'] ?? '');
      case 'notification.joinedGroup.message':
        return loc.notificationJoinedGroupMessage(args['groupName'] ?? '');
      case 'notification.invitation.message':
        return loc.notificationInvitationMessage(args['groupName'] ?? '');
      case 'notification.invitationDenied.message':
        return loc.notificationInvitationDeniedMessage(
          args['userName'] ?? '',
          args['groupName'] ?? '',
        );
      case 'notification.userAccepted.message':
        return loc.notificationUserAcceptedMessage(
          args['userName'] ?? '',
          args['groupName'] ?? '',
        );
      case 'notification.groupEdited.message':
        return loc.notificationGroupEditedMessage(args['groupName'] ?? '');
      case 'notification.groupDeleted.message':
        return loc.notificationGroupDeletedMessage(args['groupName'] ?? '');
      case 'notification.userRemoved.message':
        return loc.notificationUserRemovedMessage(
          args['groupName'] ?? '',
          args['adminName'] ?? '',
        );
      case 'notification.adminUserRemoved.message':
        return loc.notificationAdminUserRemovedMessage(
          args['userName'] ?? '',
          args['groupName'] ?? '',
        );
      case 'notification.userLeft.message':
        return loc.notificationUserLeftMessage(
          args['userName'] ?? '',
          args['groupName'] ?? '',
        );
      case 'notification.groupUpdate.message':
        return loc.notificationGroupUpdateMessage(
          args['editorName'] ?? '',
          args['groupName'] ?? '',
        );
      case 'notification.groupDeletedAll.message':
        return loc.notificationGroupDeletedAllMessage(args['groupName'] ?? '');

      // 🔹 Event-related messages
      case 'notification.event.reminder.message':
        return loc.notificationEventReminderMessage(args['eventTitle'] ?? '');
      case 'notification.event.created.message':
        return loc.notificationEventCreatedMessage(args['eventTitle'] ?? '');
      case 'notification.event.updated.message':
        return loc.notificationEventUpdatedMessage(args['eventTitle'] ?? '');
      case 'notification.event.deleted.message':
        return loc.notificationEventDeletedMessage(args['eventTitle'] ?? '');
      case 'notification.recurrenceAdded.message':
        return loc.notificationRecurrenceAddedMessage(args['title'] ?? '');
      case 'notification.eventMarkedDone.message':
        return loc.notificationEventMarkedDoneMessage(
          args['eventTitle'] ?? '',
          args['userName'] ?? '',
        );
      case 'notification.eventReopened.message':
        return loc.notificationEventReopenedMessage(
          args['eventTitle'] ?? '',
          args['userName'] ?? '',
        );

      //Reminder notifications message
      case 'notification.event.started.message':
        return loc.notificationEventStartedMessage(args['eventTitle'] ?? '');
      case 'notification.event.concurrentCreated.message':
        final eventTitle = _stringArg(args, 'eventTitle');
        final overlapCount = _intArg(args, 'overlapCount');
        final fallback = fallbackMessage.trim();
        if (eventTitle != null && overlapCount != null) {
          return isEs
              ? 'El evento "$eventTitle" se solapa con $overlapCount evento(s) existente(s).'
              : 'The event "$eventTitle" overlaps $overlapCount existing event(s).';
        }
        if (eventTitle != null) {
          return isEs
              ? 'El evento "$eventTitle" tiene un solapamiento con otros eventos.'
              : 'The event "$eventTitle" overlaps with other events.';
        }
        return fallback.isNotEmpty
            ? fallback
            : (isEs
                ? 'Se ha detectado un conflicto entre eventos.'
                : 'An event conflict was detected.');
      case 'notification.recurringInvoice.draftCreated.message':
      case 'notification.recurring.invoice.draft.created.message':
      case 'notification.recurringDraftInvoice.created.message':
        return _localizedRecurringDraftInvoiceMessage(loc) ?? fallbackMessage;

      case 'notification.invoice.issued.message':
      case 'notification.receipt.issued.message':
      case 'notification.presupuesto.issued.message':
        final documentNumber = _stringArg(args, 'documentNumber');
        final clientName = _stringArg(args, 'clientName');
        final amount = _doubleArg(args, 'amount');
        final currency = _stringArg(args, 'currency') ?? 'EUR';
        final fallback = fallbackMessage.trim();

        final parts = <String>[
          if (documentNumber != null) documentNumber,
          if (clientName != null) clientName,
          if (amount != null)
            _formatNotificationCurrency(
              amount,
              currency: currency,
              locale: loc.localeName,
            ),
        ];
        if (parts.isNotEmpty) {
          return parts.join(' · ');
        }
        return fallback.isNotEmpty
            ? fallback
            : (isEs
                ? 'El documento ha sido emitido correctamente.'
                : 'The document was issued successfully.');

      default:
        final bankExpensesMessage = _localizedBankExpensesDetectedMessage(loc);
        if (bankExpensesMessage != null) return bankExpensesMessage;
        final recurringMessage = _localizedRecurringDraftInvoiceMessage(loc);
        if (recurringMessage != null) return recurringMessage;
        return fallbackMessage;
    }
  }

  String? _localizedRecurringDraftInvoiceMessage(AppLocalizations loc) {
    if (!_isRecurringDraftInvoiceNotification(this)) return null;
    final clientName = _stringArg(args, 'clientName');
    final recurrenceName =
        _stringArg(args, 'recurrenceName') ?? _stringArg(args, 'seriesName');
    final amount = _doubleArg(args, 'amount');
    final currency = _stringArg(args, 'currency') ?? 'EUR';

    if (clientName != null && recurrenceName != null && amount != null) {
      return loc.notificationRecurringDraftInvoiceCreatedMessage(
        clientName,
        recurrenceName,
        _formatNotificationCurrency(amount, currency: currency, locale: loc.localeName),
      );
    }
    if (clientName != null && recurrenceName != null) {
      return loc.notificationRecurringDraftInvoiceCreatedMessageNoAmount(
        clientName,
        recurrenceName,
      );
    }
    return loc.notificationRecurringDraftInvoiceCreatedMessageFallback;
  }

  String? _localizedBankExpensesDetectedMessage(AppLocalizations loc) {
    if (!_isBankExpensesDetectedNotification(this) &&
        titleKey != 'notification.bankExpensesDetected.title' &&
        titleKey != 'notification.bank.expenses.detected.title' &&
        titleKey != 'notification.suspectExpenses.detected.title' &&
        messageKey != 'notification.bankExpensesDetected.message' &&
        messageKey != 'notification.bank.expenses.detected.message' &&
        messageKey != 'notification.suspectExpenses.detected.message') {
      return null;
    }

    final count =
        _intArg(args, 'count') ??
        _intArg(args, 'expenseCount') ??
        _intArg(args, 'expensesCount') ??
        _intArg(args, 'suspectCount') ??
        _intArg(args, 'detectedCount');
    final amount =
        _doubleArg(args, 'amount') ??
        _doubleArg(args, 'totalAmount') ??
        _doubleArg(args, 'amountTotal') ??
        _doubleArg(args, 'total');
    final currency = _stringArg(args, 'currency') ?? 'EUR';
    if (count == null || amount == null) {
      return null;
    }
    return loc.notificationBankExpensesDetectedMessage(
      count,
      _formatNotificationCurrency(
        amount,
        currency: currency,
        locale: loc.localeName,
      ),
    );
  }
}

bool _isRecurringDraftInvoiceNotification(NotificationUser n) {
  final title = n.fallbackTitle.trim().toLowerCase();
  final key = n.titleKey.trim().toLowerCase();
  return key.contains('recurringinvoice') ||
      key.contains('recurring.invoice') ||
      key.contains('recurringdraftinvoice') ||
      title == 'recurring draft invoice created' ||
      title == 'borrador de factura recurrente creado';
}

bool _isBankExpensesDetectedNotification(NotificationUser notification) {
  final normalizedTitle = notification.fallbackTitle.trim().toLowerCase();
  final normalizedMessage = notification.fallbackMessage.trim().toLowerCase();
  return normalizedTitle == 'bank expenses detected' ||
      normalizedTitle == 'gastos bancarios detectados' ||
      (normalizedMessage.contains('bank expenses') &&
          normalizedMessage.contains('detected')) ||
      (normalizedMessage.contains('gastos bancarios') &&
          normalizedMessage.contains('detect'));
}

String _formatNotificationCurrency(
  double amount, {
  required String currency,
  required String locale,
}) {
  final normalizedCurrency = currency.trim().toUpperCase();
  if (normalizedCurrency == 'EUR') {
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    ).format(amount);
  }
  return NumberFormat.simpleCurrency(
    name: normalizedCurrency,
    decimalDigits: 2,
    locale: locale,
  ).format(amount);
}

String? _stringArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}

int? _intArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _doubleArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
