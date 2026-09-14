import 'package:flutter/foundation.dart';
import 'package:hexora/services/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/services/time_tracking/api/i_time_tracking_api_client.dart';
import 'package:hexora/services/time_tracking/api/time_tracking_api_client.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/groups/event/api/event_api_client.dart';
import 'package:hexora/services/groups/event/api/i_event_api_client.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/groups/event/repository/event_repository.dart';
import 'package:hexora/services/groups/event/repository/i_event_repository.dart';
import 'package:hexora/services/groups/event/resolver/event_group_resolver.dart';
import 'package:hexora/services/groups/api/group_api_client.dart';
import 'package:hexora/services/groups/api/i_group_api_client.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/repository/group_repository.dart';
import 'package:hexora/services/groups/repository/i_group_repository.dart';
import 'package:hexora/services/groups/invite/api/invite_api_client.dart';
import 'package:hexora/services/groups/invite/domain/invite_domain.dart';
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';
import 'package:hexora/services/groups/recurrence/recurrence_rule_api_client.dart';
import 'package:hexora/services/mail/api/i_mail_api_client.dart';
import 'package:hexora/services/mail/api/mail_api_client.dart';
import 'package:hexora/services/mail/domain/mail_domain.dart';
import 'package:hexora/services/mail/repository/i_mail_repository.dart';
import 'package:hexora/services/mail/repository/mail_repository.dart';
import 'package:hexora/services/telegram/api/telegram_api_client.dart';
import 'package:hexora/services/telegram/domain/telegram_domain.dart';
import 'package:hexora/services/user/repository/i_user_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/utils/location/geofenced_visit_tracking_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> featureProviders = [
  // Recurrence rules
  Provider<RecurrenceRuleApiClient>(create: (_) => RecurrenceRuleApiClient()),

  // Events
  Provider<IEventApiClient>(
    create: (ctx) => EventApiClient(
      ruleService: ctx.read<RecurrenceRuleApiClient>(),
    ),
  ),
  Provider<IEventRepository>(
    create: (ctx) => EventRepository(
      apiClient: ctx.read<IEventApiClient>(),
      tokenSupplier: () async {
        final token = await ctx.read<AuthService>().getToken();
        if (token == null) throw Exception('Not authenticated');
        return token;
      },
    ),
  ),

  // Groups
  Provider<IGroupApiClient>(create: (_) => HttpGroupApiClient()),
  Provider<IGroupRepository>(
    create: (ctx) => GroupRepository(
      apiClient: ctx.read<IGroupApiClient>(),
      tokenSupplier: () async {
        final token = await ctx.read<AuthService>().getToken();
        if (token == null) throw Exception('Not authenticated');
        return token;
      },
    ),
  ),
  Provider<GroupEventResolver>(
    create: (ctx) => GroupEventResolver(
      ruleService: ctx.read<RecurrenceRuleApiClient>(),
    ),
  ),
  ChangeNotifierProvider(
    create: (ctx) => GroupDomain(
      groupRepository: ctx.read<IGroupRepository>(),
      userRepository: ctx.read<IUserRepository>(),
      groupEventResolver: ctx.read<GroupEventResolver>(),
      user: null,
    ),
  ),

  // Mail
  Provider<IMailApiClient>(
    create: (ctx) => MailApiClient(client: ctx.read<http.Client>()),
  ),
  Provider<IMailRepository>(
    create: (ctx) => MailRepository(
      apiClient: ctx.read<IMailApiClient>(),
      tokenSupplier: () async {
        final token = await ctx.read<AuthService>().getToken();
        if (token == null) throw Exception('Not authenticated');
        return token;
      },
    ),
  ),
  ChangeNotifierProvider(
    create: (ctx) => MailDomain(repository: ctx.read<IMailRepository>()),
  ),

  // Telegram
  Provider<ITelegramApiClient>(
    create: (ctx) => TelegramApiClient(client: ctx.read<http.Client>()),
  ),
  ChangeNotifierProvider(
    create: (ctx) => TelegramDomain(apiClient: ctx.read<ITelegramApiClient>()),
  ),

  // Invitations
  Provider<InvitationRepository>(
    create: (_) => HttpInvitationRepository(InvitationApiClient()),
  ),
  ChangeNotifierProvider<InvitationDomain>(
    create: (ctx) => InvitationDomain(
      repository: ctx.read<InvitationRepository>(),
      tokenSupplier: () => ctx.read<AuthService>().getToken(),
    ),
  ),

  // Time tracking (your feature)
  Provider<ITimeTrackingApiClient>(create: (_) => TimeTrackingApiClient()),
  Provider<ITimeTrackingRepository>(
    create: (ctx) => TimeTrackingRepository(ctx.read<ITimeTrackingApiClient>()),
  ),
  ChangeNotifierProvider<GeofencedVisitTrackingService>(
    create: (ctx) => GeofencedVisitTrackingService(
      api: ctx.read<ITimeTrackingApiClient>(),
      userDomain: ctx.read<UserDomain>(),
    )..restore(),
  ),

  // EventDomain: depends on GroupDomain + IEventRepository
  ProxyProvider3<GroupDomain, IEventRepository, GroupEventResolver,
      EventDomain?>(
    create: (_) => null,
    update: (ctx, groupDomain, eventRepo, resolver, previous) {
      final current = groupDomain.currentGroup;
      if (current == null) return null;

      // Reuse the existing instance if same group
      if (previous != null && previous.groupId == current.id) {
        return previous;
      }

      final edm = EventDomain(
        const [],
        context: ctx,
        group: current,
        repository: eventRepo,
        groupDomain: groupDomain,
        resolver: resolver, // ðŸ‘ˆ NEW
      );

      edm.onExternalEventUpdate = previous?.onExternalEventUpdate ??
          () => debugPrint('⚠️ No calendar UI registered.');

      return edm;
    },
  ),
];
