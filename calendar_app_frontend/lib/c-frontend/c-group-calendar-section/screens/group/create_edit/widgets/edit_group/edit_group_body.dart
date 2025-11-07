import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/domain/invite_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/controllers/group_update_controller.dart';
// ❌ no longer needed: image_picker_controller.dart
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/services/group_init_service.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/edit_group/edit_group_header.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/edit_group/edit_group_ppl.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/navigation/edit_group_bottom_nav.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditGroupBody extends StatefulWidget {
  final Group group;
  final List<User> users;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final NotificationDomain notificationDomain;

  const EditGroupBody({
    Key? key,
    required this.group,
    required this.users,
    required this.userDomain,
    required this.groupDomain,
    required this.notificationDomain,
  }) : super(key: key);

  @override
  _EditGroupBodyState createState() => _EditGroupBodyState();
}

class _EditGroupBodyState extends State<EditGroupBody> {
  // controller-based fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late String _imageURL;
  late User? _currentUser;

  // removed: XFile? _selectedImage;
  bool _isUploading = false;
  String? _photoBlobName;

  final GlobalKey<EditGroupPeopleState> _peopleKey =
      GlobalKey<EditGroupPeopleState>();

  @override
  void initState() {
    super.initState();

    _currentUser = widget.userDomain.user;

    // Initialize via existing service for consistency, then set up controllers.
    final initService = GroupInitializationService(
      group: widget.group,
      descriptionController: TextEditingController(),
    );

    _nameController = TextEditingController(text: initService.groupName);
    _descriptionController = initService.descriptionController;
    _imageURL = initService.imageURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // NEW: called by GroupImage when a file is picked
  Future<void> _onPicked(XFile file) async {
    setState(() => _isUploading = true);
    try {
      await widget.groupDomain.groupRepository.uploadAndCommitGroupPhoto(
        groupId: widget.group.id,
        file: File(file.path),
      );

      await widget.groupDomain.refreshGroupsForCurrentUser(widget.userDomain);

      final fresh = await widget.groupDomain.groupRepository
          .getGroupById(widget.group.id);

      if (!mounted) return;
      setState(() {
        _imageURL = fresh.photoUrl ?? _imageURL;
        _photoBlobName = fresh.photoBlobName ?? _photoBlobName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload group photo: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isUploading = false);
    }
  }

  // Optional: if you support removing the image
  Future<void> _onRemove() async {
    // If you also clear it server-side, do that here.
    setState(() {
      _imageURL = '';
      _photoBlobName = null;
    });
  }

  Future<void> _handleUpdate() async {
    final peopleState = _peopleKey.currentState;
    if (peopleState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, people list not ready.')),
      );
      return;
    }

    // Final roles are keyed by **userId**
    final Map<String, String> finalRoles = peopleState.getFinalRoles();

    // Compute newly invited userIds = roles not in current member set
    final currentMembers = widget.group.userIds.toSet()
      ..add(widget.group.ownerId);
    final newlyInvitedUserIds =
        finalRoles.keys.where((uid) => !currentMembers.contains(uid)).toList();

    final invitationDomain = context.read<InvitationDomain>();

    final controller = GroupUpdateController(
      context: context,
      originalGroup: widget.group,
      groupName: _nameController.text,
      groupDescription: _descriptionController.text,
      imageUrl: _imageURL,
      currentUser: _currentUser!,
      userRoles: finalRoles,
      newlyInvitedUserIds: newlyInvitedUserIds,
      userDomain: widget.userDomain,
      groupDomain: widget.groupDomain,
      invitationDomain: invitationDomain,
    );

    await controller.performGroupUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Group')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                EditGroupHeader(
                  imageUrl: _imageURL, // NEW name
                  isUploading:
                      _isUploading, // optional dim/spinner inside widget
                  onPicked: _onPicked, // NEW: receives XFile
                  onRemove: _onRemove, // optional
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            EditGroupPeople(
              key: _peopleKey,
              group: widget.group,
              initialUsers: widget.users,
              userDomain: widget.userDomain,
              groupDomain: widget.groupDomain,
              notificationDomain: widget.notificationDomain,
            ),
          ],
        ),
      ),
      bottomNavigationBar: EditGroupBottomNav(onUpdate: _handleUpdate),
    );
  }
}
