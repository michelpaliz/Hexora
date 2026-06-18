// routes.dart

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/routes/calendar/group_calendar_loader.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/home_page/home_page.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/group_dashboard.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/header_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_callback_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/analytics/statements_analytics_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/group_insights_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/screen/group_members_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/notifications/group_notifications_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/services_clients_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/expense_ocr_reprocess_results_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/recurring_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/workers_hub_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/create_worker/form/create_worker_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/worker_time_tracking_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/models/edit_group_data.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/group-settings/group_settings.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/edit_screen/screen/edit_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/download_app/download_app_view.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/forgot_password.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/login/form/login_view.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/reset_password/reset_password_screen.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/ui/register_view.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/verify_email/verify_email_view.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/verify_email/verify_success_view.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/show_notifications.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/agenda_screen.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/profile_edit_screen.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/view/profile_view_screen.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/screens/settings.dart';

final Map<String, WidgetBuilder> routes = {
  AppRoutes.settings: (context) => const Settings(),
  AppRoutes.loginRoute: (context) => const LoginView(),
  AppRoutes.registerRoute: (context) => const RegisterView(),
  AppRoutes.forgotPasswordRoute: (context) => const ForgotPasswordScreen(),
  AppRoutes.resetPasswordRoute: (context) => const ResetPasswordScreen(),
  AppRoutes.passwordRecoveryRoute: (context) => const ForgotPasswordScreen(),
  AppRoutes.verifyEmailRoute: (context) => const VerifyEmailView(),
  AppRoutes.verifyEmailSuccessRoute: (context) =>
      const VerifyEmailSuccessView(),
  AppRoutes.downloadApp: (context) => const DownloadAppView(),
  AppRoutes.downloadAppShort: (context) => const DownloadAppView(),
  AppRoutes.enableBanking: (context) => EnableBankingScreen.fromRoute(context),
  AppRoutes.enableBankingCallback: (context) =>
      const EnableBankingCallbackScreen(),
  AppRoutes.statementsAnalytics: (context) => const StatementsAnalyticsScreen(),
  AppRoutes.groupDashboard: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return GroupDashboard(group: group);
  },

  AppRoutes.groupInsights: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return GroupInsightsScreen(group: group);
  },

  // AppRoutes.showGroups: (context) => GroupListSection(),

  AppRoutes.showGroups: (context) => const GroupListSection(fullPage: true),

  AppRoutes.editEvent: (context) {
    final event = ModalRoute.of(context)?.settings.arguments as Event?;
    return event != null
        ? EditEventScreen(event: event)
        : const SizedBox.shrink();
  },

  AppRoutes.createGroupData: (context) => const CreateGroupData(),
  AppRoutes.showNotifications: (context) {
    final user = ModalRoute.of(context)?.settings.arguments as User?;
    return user != null
        ? ShowNotifications(user: user)
        : const SizedBox.shrink();
  },
  AppRoutes.groupNotifications: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    return group != null
        ? GroupNotificationsScreen(group: group)
        : const SizedBox.shrink();
  },
  AppRoutes.expenseOcrReprocessResults: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ExpenseOcrReprocessResultsArgs) {
      return ExpenseOcrReprocessResultsScreen(
        groupId: args.groupId,
        jobId: args.jobId,
      );
    }
    if (args is Map) {
      final groupId = (args['groupId'] ?? '').toString();
      final jobId = (args['jobId'] ?? '').toString();
      if (groupId.isEmpty || jobId.isEmpty) return const SizedBox.shrink();
      return ExpenseOcrReprocessResultsScreen(groupId: groupId, jobId: jobId);
    }
    return const SizedBox.shrink();
  },
  AppRoutes.groupCalendar: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return GroupCalendarLoader(args: args);
  },

  AppRoutes.addEvent: (context) {
    final group = ModalRoute.of(context)!.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return AddEventScreen(group: group);
  },
  AppRoutes.eventDetail: (context) {
    final event = ModalRoute.of(context)?.settings.arguments as Event?;
    return event != null
        ? EventDetailScreen(event: event)
        : const SizedBox.shrink();
  },
  AppRoutes.editGroupData: (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as EditGroupArguments;
    return EditGroupData(group: args.group, users: args.users);
  },
  AppRoutes.homePage: (context) => const HomePage(),
  AppRoutes.groupSettings: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    return group != null
        ? GroupSettings(group: group)
        : const SizedBox.shrink();
  },
  AppRoutes.groupServicesClients: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return ServicesClientsScreen(group: group);
  },
  AppRoutes.groupIncome: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Group? group;
    String? initialMenu;
    String? initialInvoiceId;
    String? initialReceiptId;
    String? initialBudgetId;
    if (args is Group) {
      group = args;
    } else if (args is GroupInvoicesRouteArgs) {
      group = args.group;
      initialMenu = args.initialMenu;
      initialInvoiceId = args.initialInvoiceId;
      initialReceiptId = args.initialReceiptId;
      initialBudgetId = args.initialBudgetId;
    } else if (args is Map) {
      group = args['group'] as Group?;
      initialMenu = args['initialMenu']?.toString();
      initialInvoiceId = args['initialInvoiceId']?.toString();
      initialReceiptId = args['initialReceiptId']?.toString();
      initialBudgetId = args['initialBudgetId']?.toString();
    }
    if (group == null) return const SizedBox.shrink();
    return GroupInvoicesScreen(
      group: group,
      initialMenu: initialMenu,
      initialInvoiceId: initialInvoiceId,
      initialReceiptId: initialReceiptId,
      initialBudgetId: initialBudgetId,
    );
  },
  AppRoutes.groupInvoices: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Group? group;
    String? initialMenu;
    String? initialInvoiceId;
    String? initialReceiptId;
    String? initialBudgetId;
    if (args is Group) {
      group = args;
    } else if (args is GroupInvoicesRouteArgs) {
      group = args.group;
      initialMenu = args.initialMenu;
      initialInvoiceId = args.initialInvoiceId;
      initialReceiptId = args.initialReceiptId;
      initialBudgetId = args.initialBudgetId;
    } else if (args is Map) {
      group = args['group'] as Group?;
      initialMenu = args['initialMenu']?.toString();
      initialInvoiceId = args['initialInvoiceId']?.toString();
      initialReceiptId = args['initialReceiptId']?.toString();
      initialBudgetId = args['initialBudgetId']?.toString();
    }
    if (group == null) return const SizedBox.shrink();
    return GroupInvoicesScreen(
      group: group,
      initialMenu: initialMenu,
      initialInvoiceId: initialInvoiceId,
      initialReceiptId: initialReceiptId,
      initialBudgetId: initialBudgetId,
    );
  },
  AppRoutes.groupExpenses: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return GastosModuleScreen(group: group);
  },
  AppRoutes.recurringInvoices: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return RecurringInvoicesScreen(group: group);
  },
  AppRoutes.agenda: (_) => const AgendaScreen(),

  // NEW: Profile details (read-only / pretty view)
  AppRoutes.profileDetails: (_) => const ProfileViewScreen(),

  // Existing edit profile screen
  AppRoutes.profile: (_) => const ProfileEditScreen(),

  AppRoutes.groupMembers: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return GroupMembersScreen(group: group);
  },
  AppRoutes.groupTimeTracking: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return WorkersHubScreen(group: group);
  },
  AppRoutes.headerSection: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    return group != null
        ? GroupHeaderScreen(group: group)
        : const SizedBox.shrink();
  },
  AppRoutes.createWorker: (context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    if (group == null) return const SizedBox.shrink();
    return CreateWorkerScreen(group: group);
  },
  AppRoutes.createTimeEntry: (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return const SizedBox.shrink();
    final group = args['group'] as Group;
    final workers = args['workers'] as List<Worker>;
    return CreateTimeEntryScreen(group: group, workers: workers);
  },
  AppRoutes.workerTimeTracking: (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return const SizedBox.shrink();
    final group = args['group'] as Group;
    final worker = args['worker'] as Worker;
    return WorkerTimeTrackingScreen(group: group, worker: worker);
  },
};
