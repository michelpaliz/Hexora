import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/blobUploader/blobRepository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:image_picker/image_picker.dart';

class PhotoController extends ChangeNotifier {
  final BlobRepository _repo;
  final UserDomain _userDomain;
  final GroupDomain _groupDomain;

  PhotoController({
    required BlobRepository repo,
    required UserDomain userDomain,
    required GroupDomain groupDomain,
  })  : _repo = repo,
        _userDomain = userDomain,
        _groupDomain = groupDomain;

  bool busy = false;
  XFile? pickedImage;

  Future<void> pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      pickedImage = img;
      notifyListeners();
    }
  }

  void clear() {
    pickedImage = null;
    notifyListeners();
  }

  /// Upload avatar and refresh the user from the backend (server truth).
  Future<bool> uploadUserAvatar(BuildContext context) async {
    if (pickedImage == null) return false;
    final u = _userDomain.user;
    if (u == null) return false;

    busy = true;
    notifyListeners();
    try {
      // This should upload to blob storage and commit on your backend.
      await _repo.uploadUserAvatar(file: File(pickedImage!.path));

      // Refresh the signed-in user so UI gets the canonical URL.
      final fresh = await _userDomain.getUser();
      if (fresh != null) {
        _userDomain.setCurrentUser(fresh);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')),
        );
      }
      clear();
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Upload group photo and refresh the repo-backed groups stream.
  Future<bool> uploadGroupPhoto(
    BuildContext context, {
    required String groupId,
  }) async {
    if (pickedImage == null) return false;

    busy = true;
    notifyListeners();
    try {
      // Upload + commit (BlobRepository should handle both steps)
      await _repo.uploadGroupPhoto(
        groupId: groupId,
        file: File(pickedImage!.path),
      );

      // Pull server truth so subscribers (e.g., lists/calendars) update.
      await _groupDomain.refreshGroupsForCurrentUser(_userDomain);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group photo updated')),
        );
      }
      clear();
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group photo: $e')),
        );
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
