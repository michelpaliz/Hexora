import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:image_picker/image_picker.dart';

class UserViewModel extends ChangeNotifier {
  // --- Dependencies ---
  late UserDomain _userDomain;
  BuildContext? _context;

  // --- UI state / form fields ---
  final displayNameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  bool saving = false;
  bool loading = false;

  // Avatar preview (local only until saved)
  XFile? pickedAvatar;

  // Listen to changes from management (e.g., user updated elsewhere)
  VoidCallback? _userSub;

  // ---------- Lifecycle ----------
  void initialize({
    required BuildContext context,
    required UserDomain userDomain,
  }) {
    _context = context;
    _userDomain = userDomain;

    // seed form from current user (if any)
    _hydrateFrom(_userDomain.user);

    // keep in sync with management
    _userSub = () => _hydrateFrom(_userDomain.currentUserNotifier.value);
    _userDomain.currentUserNotifier.addListener(_userSub!);
  }

  @override
  void dispose() {
    displayNameCtrl.dispose();
    bioCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();
    if (_userSub != null) {
      _userDomain.currentUserNotifier.removeListener(_userSub!);
    }
    super.dispose();
  }

  // ---------- UI helpers ----------
  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      pickedAvatar = img;
      notifyListeners();
    }
  }

  void clearAvatarSelection() {
    pickedAvatar = null;
    notifyListeners();
  }

  // ---------- Actions ----------
  Future<void> refreshCurrentUserFromServer() async {
    loading = true;
    notifyListeners();
    try {
      final fresh = await _userDomain.getUser();
      if (fresh != null) {
        _userDomain.updateCurrentUser(fresh);
      }
      _showSnack('Profile refreshed');
    } catch (e) {
      _showSnack('Failed to refresh profile');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile() async {
    final u = _userDomain.user;
    if (u == null) {
      _showSnack('No user in session');
      return false;
    }

    // simple validation example
    if (displayNameCtrl.text.trim().isEmpty) {
      _showSnack('Display name is required');
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      // 1) Update basic fields
      final updated = u.copyWith(
        displayName: displayNameCtrl.text.trim(),
        bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
        phoneNumber:
            phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        location:
            locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      );

      final ok = await _userDomain.updateUser(updated);
      if (!ok) {
        _showSnack('Could not save profile');
        saving = false;
        notifyListeners();
        return false;
      }

      _showSnack('Profile saved');
      return true;
    } catch (e) {
      _showSnack('Save failed');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  // ---------- Internals ----------
  void _hydrateFrom(User? u) {
    if (u == null) return;
    displayNameCtrl.text = u.userName;
    bioCtrl.text = u.bio ?? '';
    phoneCtrl.text = u.phoneNumber ?? '';
    locationCtrl.text = u.location ?? '';
    notifyListeners();
  }

  void _showSnack(String msg) {
    final ctx = _context;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
