import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_runtime.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_sheet.dart';
import 'package:provider/provider.dart';

class InsightsChatFab extends StatefulWidget {
  const InsightsChatFab({
    super.key,
    required this.groupId,
    this.group,
    this.heroTag = 'insights-chat-fab',
  });

  final String heroTag;
  final String groupId;
  final Group? group;

  @override
  State<InsightsChatFab> createState() => _InsightsChatFabState();
}

class _InsightsChatFabState extends State<InsightsChatFab> {
  late InsightsChatRuntime _runtime;
  bool _hasRuntime = false;
  int _lastBackgroundEvents = 0;

  @override
  void initState() {
    super.initState();
    _bindRuntime(widget.groupId);
  }

  @override
  void didUpdateWidget(covariant InsightsChatFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _bindRuntime(widget.groupId);
      if (_canUseAiChat()) unawaited(_runtime.ensureLoaded(context));
    }
  }

  void _bindRuntime(String groupId) {
    if (_hasRuntime) _runtime.removeListener(_onRuntimeChanged);
    _runtime = InsightsChatRuntime.instanceFor('panel::$groupId');
    _hasRuntime = true;
    _lastBackgroundEvents = _runtime.backgroundReplyEvents;
    _runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_canUseAiChat()) unawaited(_runtime.ensureLoaded(context));
  }

  bool _canUseAiChat() {
    final group = widget.group;
    if (group == null) return true;
    return canManagePremiumFeature(
      group,
      context.read<UserDomain?>()?.user?.id,
      PremiumFeature.aiChat,
    );
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final events = _runtime.backgroundReplyEvents;
    if (events > _lastBackgroundEvents &&
        !_runtime.isSheetOpen &&
        ModalRoute.of(context)?.settings.name == AppRoutes.groupDashboard) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.insightsChatAnswerReady)),
      );
    }
    _lastBackgroundEvents = events;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _runtime.removeListener(_onRuntimeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != AppRoutes.groupDashboard) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      heroTag: widget.heroTag,
      tooltip: l.insightsChatFabTooltip,
      onPressed: () => _openSheet(context),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: _runtime.sending ? const Offset(0, -0.06) : Offset.zero,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              _runtime.sending
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
            ),
            if (_runtime.unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _runtime.unreadCount > 9
                        ? '9+'
                        : _runtime.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    final allowed = _canUseAiChat();
    return showModalBottomSheet<void>(
      sheetAnimationStyle: HexoraMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => allowed
          ? InsightsChatSheet(
              groupId: widget.groupId,
              runtime: _runtime,
            )
          : PremiumFeatureRequestScreen(
              group: widget.group,
              feature: PremiumFeatureRequest.aiChat,
              embedded: true,
            ),
    );
  }
}

class InsightsChatPanel extends StatelessWidget {
  const InsightsChatPanel({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return InsightsChatSheet(
      groupId: groupId,
      embedded: true,
      runtime: InsightsChatRuntime.instanceFor('panel::$groupId'),
    );
  }
}
