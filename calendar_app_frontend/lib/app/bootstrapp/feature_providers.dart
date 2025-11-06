import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_service.dart';
import 'package:hexora/b-backend/auth_user/user/repository/i_user_repository.dart';
import 'package:hexora/b-backend/business_logic/worker/api/i_time_tracking_api_client.dart';
import 'package:hexora/b-backend/business_logic/worker/api/time_tracking_api_client.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/api/event_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/api/i_event_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/resolver/event_group_resolver.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/group_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/i_group_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/group_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/i_group_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/api/invite_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/domain/invite_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/recurrenceRule/recurrence_rule_api_client.dart';
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

  // EventDomain: depends on GroupDomain + IEventRepository
  ProxyProvider2<GroupDomain, IEventRepository, EventDomain?>(
    create: (_) => null,
    update: (ctx, groupDomain, eventRepo, previous) {
      final current = groupDomain.currentGroup;
      if (current == null) return null;

      if (previous != null && previous.groupId == current.id) {
        return previous;
      }

      final edm = EventDomain(
        const [],
        context: ctx,
        group: current,
        repository: eventRepo,
        groupDomain: groupDomain,
      );
      edm.onExternalEventUpdate = previous?.onExternalEventUpdate ??
          () => debugPrint('⚠️ No calendar UI registered.');
      return edm;
    },
  ),
];
