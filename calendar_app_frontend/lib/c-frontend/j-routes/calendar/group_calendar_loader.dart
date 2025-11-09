// lib/c-frontend/routes/group_calendar_loader.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/c-frontend/j-routes/calendar/no_calendar_screen.dart';
import 'package:provider/provider.dart';

class GroupCalendarLoader extends StatefulWidget {
  final Object? args; // Group or String groupId
  const GroupCalendarLoader({super.key, this.args});

  @override
  State<GroupCalendarLoader> createState() => _GroupCalendarLoaderState();
}

class _GroupCalendarLoaderState extends State<GroupCalendarLoader> {
  Group? _group;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _setCurrentGroupSafely(GroupDomain gm, Group g) {
    // Avoid redundant sets → prevents provider churn
    if (gm.currentGroup?.id == g.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gm.currentGroup = g; // setter already defers notify if mid-build
    });
  }

  Future<void> _resolve() async {
    final gm = context.read<GroupDomain>();
    final ud = context.read<UserDomain>();

    try {
      // Case 1: A full Group was passed
      if (widget.args is Group) {
        final g = widget.args as Group;
        _setCurrentGroupSafely(gm, g);
        if (mounted) setState(() => _group = g);
        return;
      }

      // Case 2: A groupId (String) was passed
      if (widget.args is String && (widget.args as String).isNotEmpty) {
        final groupId = widget.args as String;
        final user = ud.user;

        // Always have a direct repo fetch ready (authoritative, won't hang)
        final Future<Group?> repoFuture =
            gm.groupRepository.getGroupById(groupId);

        // Try the stream quickly, but don't block UI if it never emits
        final Future<Group?> streamFuture = () async {
          if (user == null) return null;

          // Best-effort refresh; ignore errors
          try {
            await gm.refreshGroupsForCurrentUser(ud);
          } catch (_) {}

          try {
            final list = await gm
                .watchGroupsForUser(user.id)
                .first
                .timeout(const Duration(seconds: 3), onTimeout: () => const []);

            final found = list.cast<Group?>().firstWhere(
                  (g) => g?.id == groupId,
                  orElse: () => null,
                );
            return found;
          } catch (_) {
            return null;
          }
        }();

        Group? g;
        try {
          // Prefer whichever resolves first; stream may return null → then use repo
          g = await Future.any<Group?>([
            streamFuture.then((v) => v), // may resolve to null
            repoFuture,
          ]);

          // If the "first to finish" was the stream and returned null,
          // fall back to repo result explicitly.
          if (g == null) {
            g = await repoFuture;
          }
        } catch (_) {
          // As a last resort, try repo once more to surface a clear error
          try {
            g = await repoFuture;
          } catch (e) {
            if (mounted) {
              setState(() => _error = 'Could not load group: $e');
            }
            return;
          }
        }

        if (g == null) {
          if (mounted) {
            setState(() => _error = 'Group not found ($groupId).');
          }
          return;
        }

        _setCurrentGroupSafely(gm, g);
        if (mounted) setState(() => _group = g);
        return;
      }

      if (mounted) setState(() => _error = 'Invalid group argument');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (_group == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🚦 No calendar? Show the simple white screen
    if (!_group!.hasCalendar) {
      return const NoCalendarScreen();
    }

    return MainCalendarView(group: _group!);
  }
}
