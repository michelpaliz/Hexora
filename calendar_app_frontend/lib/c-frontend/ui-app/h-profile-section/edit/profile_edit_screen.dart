import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_edit_controller.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
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
  final _controller = ProfileEditController();

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

  Future<void> _handleChangePhoto() async {
    await _controller.changePhoto(context);
    if (mounted) setState(() {}); // refresh avatar preview
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    final ok = await _controller.saveProfile(
      context: context,
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
    );
    if (mounted) setState(() => _saving = false);
    if (ok && mounted) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final user = context.watch<UserDomain>().user;
    if (user == null) {
      return MainScaffold(
          showAppBar: false, body: Center(child: Text(l.noUserLoaded)));
    }

    final cardBg = ThemeColors.cardBg(context);
    final cardShadow = ThemeColors.cardShadow(context);
    final onCard = ThemeColors.textPrimary(context);

    return MainScaffold(
      showAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(
            child:
                SafeArea(top: true, bottom: false, child: SizedBox(height: 8)),
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ProfileHeader(title: l.profile, subtitle: user.email),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: cardShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 8)),
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
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _handleChangePhoto,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: ThemeColors.contrastOn(cs.primary),
                              size: 20,
                            ),
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
                        offset: const Offset(0, 6)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l.details,
                          style: t.titleLarge.copyWith(
                              fontWeight: FontWeight.w700, color: onCard)),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(label: l.displayName, controller: _nameCtrl),
                    const SizedBox(height: 12),
                    LabeledField(label: l.username, controller: _usernameCtrl),
                    const SizedBox(height: 12),
                    LabeledField(
                        label: l.email, controller: _emailCtrl, enabled: false),
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
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _handleSave,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ThemeColors.contrastOn(cs.primary),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? l.saving : l.save,
                      style: t.buttonText
                          .copyWith(color: ThemeColors.contrastOn(cs.primary)),
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
