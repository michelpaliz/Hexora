import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/string_utils.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/common/ui_messenger.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/group_editor_state.dart/group_editor_state.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/update_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/role_policy/role_policy.dart';
import 'package:image_picker/image_picker.dart';

enum GroupEditorStatus { idle, loading, error, success }

/// The backtick character (`) in Dart is used to create a multi-line string. It allows you to write a
/// string that spans multiple lines without having to use escape characters like \n for new lines. This
/// can make your code more readable and maintainable when dealing with long strings or multiline text.

class GroupEditorViewModel extends ChangeNotifier {
  GroupEditorState _state = const GroupEditorState();
  GroupEditorStatus status = GroupEditorStatus.idle;

  final User currentUser;
  final UiMessenger ui;
  final CreateGroupUseCase createGroup;
  final InviteMembersUseCase inviteMembers;
  final UploadGroupPhotoUseCase uploadPhoto;
  final SearchUsersUseCase searchUsersUseCase; // <-- NEW
  // + inject update use case
  final UpdateGroupUseCase updateGroup;

  Group? _editingGroup;
  String? _editingGroupId;

  GroupEditorViewModel({
    required this.currentUser,
    required this.ui,
    required this.createGroup,
    required this.inviteMembers,
    required this.uploadPhoto,
    required this.searchUsersUseCase,
    required this.updateGroup,
  }) {
    _state = _state.copyWith(
      membersById: {currentUser.id: currentUser},
      roles: {currentUser.id: GroupRole.owner},
    );
  }

  GroupEditorState get state => _state;

  // Temporary alias so old widgets keep compiling
  Future<void> submitGroupFromUI() => submit();

  // setters
  void setName(String v) => _update(_state.copyWith(name: v.trim()));
  void setDescription(String v) =>
      _update(_state.copyWith(description: v.trim()));
  void setImage(XFile? f) => _update(_state.copyWith(image: f));

  bool get isEditing => _editingGroup != null;

  bool get isSubmitting => status == GroupEditorStatus.loading;
  bool get canSubmit =>
      _state.name.trim().isNotEmpty &&
      _state.description.trim().isNotEmpty &&
      !isSubmitting;

  bool canEditRole(String userId) {
    return RolePolicy.canEditRole(
      actorId: currentUser.id,
      targetId: userId,
      ownerId: currentUser.id, // in editor, current user is the owner/creator
      roleOf: (id) => _state.roles[id] ?? GroupRole.member,
    );
  }

// Seed VM when entering edit mode
  // update this
  void enterEditFrom(Group g) {
    _editingGroup = g; // ← keep the original
    _editingGroupId = g.id;
    _update(_state.copyWith(
      name: g.name,
      description: g.description,
    ));
  }

// (optional) if you want to drive dropdown options with policy too:
  List<GroupRole> assignableRolesFor(String targetUserId) {
    return RolePolicy.assignableRoles(
      actorId: currentUser.id,
      targetId: targetUserId,
      ownerId: currentUser.id,
      roleOf: (id) => _state.roles[id] ?? GroupRole.member,
      includeOwner: false, // keep owner out of UI
    );
  }

  // members
  void addMember(User u) {
    if (_state.membersById.containsKey(u.id)) return;
    final m = Map<String, User>.from(_state.membersById)..[u.id] = u;
    final r = Map<String, GroupRole>.from(_state.roles)
      ..putIfAbsent(u.id, () => GroupRole.member);
    _update(_state.copyWith(membersById: m, roles: r));
  }

  void removeMember(String userId) {
    if (userId == currentUser.id) {
      ui.showSnack("You can't remove yourself");
      return;
    }
    final m = Map<String, User>.from(_state.membersById)..remove(userId);
    final r = Map<String, GroupRole>.from(_state.roles)..remove(userId);
    _update(_state.copyWith(membersById: m, roles: r));
  }

  void setRole(String userId, GroupRole role) {
    if (userId == currentUser.id) return;
    if (_state.roles[userId] == GroupRole.owner) return;
    final r = Map<String, GroupRole>.from(_state.roles)..[userId] = role;
    _update(_state.copyWith(roles: r));
  }

  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    // ❌ return await searchUsersUseCase(ApiConstants.baseUrl, q, limit: limit);
    return await searchUsersUseCase(q,
        limit: limit); // ✅ keep infra in the use case
  }

  Future<void> submit() async {
    if (_state.name.isEmpty || _state.description.isEmpty) {
      await ui.showError('Name and description are required');
      return;
    }
    status = GroupEditorStatus.loading;
    notifyListeners();
    try {
      if (isEditing) {
        // ---------- EDIT PATH ----------
        await updateGroup(
          original:
              _editingGroup!, // or pass original Group if that’s your UC signature
          name: _state.name,
          description: _state.description,
        );

        if (_state.image != null) {
          await uploadPhoto(groupId: _editingGroupId!, file: _state.image!);
        }

        status = GroupEditorStatus.success;
        notifyListeners();
        ui.showSnack('Group updated!');
        ui.pop();
        return;
      }

      // ---------- CREATE PATH (existing) ----------
      final created = await createGroup(
        name: _state.name,
        description: _state.description,
        owner: currentUser,
      );

      await inviteMembers(
        groupId: created.id,
        members: _state.membersById.values.toList(),
        owner: currentUser,
        roles: _state.roles,
      );

      if (_state.image != null) {
        await uploadPhoto(groupId: created.id, file: _state.image!);
      }

      status = GroupEditorStatus.success;
      notifyListeners();
      ui.showSnack('Group created!');
      ui.pop();
    } catch (e) {
      status = GroupEditorStatus.error;
      notifyListeners();
      await ui.showError('Failed to ${isEditing ? 'update' : 'create'} group');
    }
  }

  void _update(GroupEditorState s) {
    _state = s;
    notifyListeners();
  }
}

typedef UserResolver = Future<User?> Function(String userId);

class GroupUndoneEventsViewModel extends ChangeNotifier {
  GroupUndoneEventsViewModel({
    required this.groupId,
    required this.currentUserId,
    required this.role,
    required IEventRepository eventRepository,
    required UserResolver userResolver,
  })  : _eventRepository = eventRepository,
        _userResolver = userResolver;

  final String groupId;
  final String currentUserId;
  final GroupRole role;
  final IEventRepository _eventRepository;
  final UserResolver _userResolver;

  bool get _canViewAll => role != GroupRole.member;

  List<Event> _pendingEvents = const [];
  List<Event> _completedEvents = const [];
  final Map<String, EventOwnerInfo> _ownerCache = {};
  final Set<String> _ownerFetchInFlight = {};
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _processingIds = <String>{};

  List<Event> get pendingEvents => List.unmodifiable(_pendingEvents);
  List<Event> get completedEvents => List.unmodifiable(_completedEvents);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventOwnerInfo? ownerInfoOf(String ownerId) => _ownerCache[ownerId];

  bool isProcessing(String eventId) =>
      _processingIds.contains(baseId(eventId));

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final events = await _eventRepository.getEventsByGroupId(groupId);
      final visibleEvents = _canViewAll
          ? events
          : events.where((event) => event.ownerId == currentUserId).toList();
      final pending = visibleEvents
          .where((event) => event.isDone != true)
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      final completed = visibleEvents
          .where((event) => event.isDone == true)
          .toList()
        ..sort((a, b) =>
            (b.completedAt ?? b.endDate).compareTo(a.completedAt ?? a.endDate));
      _pendingEvents = pending;
      _completedEvents = completed;
      await _ensureOwnersLoaded([...pending, ...completed]);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markEventAsDone(String eventId) async {
    final key = baseId(eventId);
    if (key.isEmpty || _processingIds.contains(key)) return;

    if (!_canViewAll &&
        !_pendingEvents.any((event) =>
            baseId(event.id) == key && event.ownerId == currentUserId)) {
      return;
    }

    _processingIds.add(key);
    notifyListeners();

    try {
      final updated =
          await _eventRepository.markEventAsDone(eventId, isDone: true);
      _pendingEvents = _pendingEvents
          .where((event) => baseId(event.id) != baseId(updated.id))
          .toList();
      if (_canViewAll || updated.ownerId == currentUserId) {
        final updatedCompleted = List<Event>.from(_completedEvents)
          ..add(updated)
          ..sort((a, b) => (b.completedAt ?? b.endDate)
              .compareTo(a.completedAt ?? a.endDate));
        _completedEvents = updatedCompleted;
      }
      await _ensureOwnersLoaded([updated]);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _processingIds.remove(key);
      notifyListeners();
    }
  }

  Future<void> _ensureOwnersLoaded(Iterable<Event> events) async {
    final idsToFetch = <String>{};
    for (final event in events) {
      final ownerId = event.ownerId;
      if (ownerId.isEmpty) continue;
      if (_ownerCache.containsKey(ownerId)) continue;
      if (_ownerFetchInFlight.contains(ownerId)) continue;
      idsToFetch.add(ownerId);
    }
    if (idsToFetch.isEmpty) return;
    _ownerFetchInFlight.addAll(idsToFetch);
    try {
      await Future.wait(idsToFetch.map((id) async {
        try {
          final user = await _userResolver(id);
          if (user != null) {
            _ownerCache[id] = EventOwnerInfo.fromUser(user);
          } else {
            _ownerCache[id] = EventOwnerInfo.fallback(id);
          }
        } catch (_) {
          _ownerCache[id] = EventOwnerInfo.fallback(id);
        }
      }));
    } finally {
      _ownerFetchInFlight.removeAll(idsToFetch);
      notifyListeners();
    }
  }
}

class EventOwnerInfo {
  final String id;
  final String displayName;
  final String? username;

  const EventOwnerInfo({
    required this.id,
    required this.displayName,
    this.username,
  });

  factory EventOwnerInfo.fromUser(User user) {
    final display = _resolveDisplayName(user);
    final username = _resolveUsername(user);
    return EventOwnerInfo(id: user.id, displayName: display, username: username);
  }

  factory EventOwnerInfo.fallback(String id) => EventOwnerInfo(
        id: id,
        displayName: id,
      );

  static String _resolveDisplayName(User user) {
    final display = (user.displayName ?? '').trim();
    if (display.isNotEmpty) return display;
    final name = user.name.trim();
    if (name.isNotEmpty) return name;
    final handle = user.userName.trim();
    if (handle.isNotEmpty) return handle;
    final email = user.email.trim();
    return email.contains('@') ? email.split('@').first : 'User';
  }

  static String? _resolveUsername(User user) {
    final handle = user.userName.trim();
    if (handle.isEmpty) return null;
    final at = handle.startsWith('@') ? handle : '@$handle';
    if ((user.displayName ?? '').trim() == at || user.name.trim() == at) {
      return null;
    }
    return at;
  }
}
