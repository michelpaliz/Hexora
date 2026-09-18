import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_runtime.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_sheet.dart';

class InsightsChatFab extends StatefulWidget {
  const InsightsChatFab({
    super.key,
    required this.groupId,
    this.heroTag = 'insights-chat-fab',
  });

  final String heroTag;
  final String groupId;

  @override
  State<InsightsChatFab> createState() => _InsightsChatFabState();
}

class _InsightsChatFabState extends State<InsightsChatFab> {
  late final InsightsChatRuntime _runtime;
  int _lastBackgroundEvents = 0;

  @override
  void initState() {
    super.initState();
    _runtime = InsightsChatRuntime.instanceFor('fab::${widget.groupId}');
    _runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_runtime.ensureLoaded(context));
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsightsChatSheet(
        groupId: widget.groupId,
        runtime: _runtime,
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
