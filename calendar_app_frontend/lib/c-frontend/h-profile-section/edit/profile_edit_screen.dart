import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/e-drawer-style-menu/main_scaffold.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'widgets/labeled_field.dart';
import 'widgets/profile_header.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserDomain>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _usernameCtrl.text = user.userName;
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final loc = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final auth = context.read<AuthProvider>();
      final token = auth.lastToken;
      final userDomain = context.read<UserDomain>();
      final user = userDomain.user;

      if (token == null || user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.notAuthenticatedOrUserMissing)),
        );
        return;
      }

      final result = await uploadImageToAzure(
        scope: 'users',
        file: File(picked.path),
        accessToken: token,
      );

      final commitResp = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blobName': result.blobName}),
      );

      if (!mounted) return;

      if (commitResp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.failedToSavePhoto}: ${commitResp.statusCode}'),
          ),
        );
        return;
      }

      final updatedUserJson =
          jsonDecode(commitResp.body) as Map<String, dynamic>;
      final updated = user.copyWith(
        photoUrl: updatedUserJson['photoUrl'] ?? result.photoUrl,
        photoBlobName: updatedUserJson['photoBlobName'] ?? result.blobName,
      );

      userDomain.updateCurrentUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.photoUpdated)),
      );
      setState(() {}); // refresh avatar
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.failedToUploadImage}: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context)!;
    final userDomain = context.read<UserDomain>();
    final user = userDomain.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final updated = user.copyWith(
        name: _nameCtrl.text.trim(),
        userName: _usernameCtrl.text.trim(),
      );
      final ok = await userDomain.updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok ? loc.profileSaved : loc.failedToSaveProfile)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = context.watch<UserDomain>().user;

    if (user == null) {
      return MainScaffold(
        showAppBar: false,
        body: Center(child: Text(loc.noUserLoaded)),
      );
    }

    final t = Theme.of(context).textTheme;

    final cardBg =
        ThemeColors.getCardBackgroundColor(context).withOpacity(0.98);
    final cardShadow = ThemeColors.getCardShadowColor(context);
    final buttonBg = ThemeColors.getButtonBackgroundColor(context);
    final buttonText = ThemeColors.getButtonTextColor(context);

    return MainScaffold(
      showAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // small, consistent top inset so it doesn't eat too much vertical space
          const SliverToBoxAdapter(
            child:
                SafeArea(top: true, bottom: false, child: SizedBox(height: 8)),
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ProfileHeader(
                title: loc.profile,
                subtitle: user.email,
              ),
            ),
          ),

          // Avatar + camera action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    // subtle elevated ring behind avatar for a more modern look
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cardShadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        user: user,
                        fetchReadSas: (_) async => null,
                        radius: 52,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _changePhoto,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: buttonBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cardShadow,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                color: buttonText, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Section label — subtle
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        loc.details,
                        style:
                            t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),

                    LabeledField(label: loc.displayName, controller: _nameCtrl),
                    const SizedBox(height: 12),
                    LabeledField(
                        label: loc.username, controller: _usernameCtrl),
                    const SizedBox(height: 12),
                    LabeledField(
                        label: loc.email,
                        controller: _emailCtrl,
                        enabled: false),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Save CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: buttonText,
                            ),
                          )
                        : Icon(Icons.save_rounded, color: buttonText),
                    label: Text(
                      _saving ? loc.saving : loc.save,
                      style: t.labelLarge?.copyWith(
                          color: buttonText, fontWeight: FontWeight.w700),
                    ),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith((states) {
                        if (_saving) {
                          // Slightly dim when saving
                          return ThemeColors.getButtonBackgroundColor(context,
                                  isSecondary: true)
                              .withOpacity(0.7);
                        }
                        return buttonBg;
                      }),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      elevation: MaterialStateProperty.all(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
