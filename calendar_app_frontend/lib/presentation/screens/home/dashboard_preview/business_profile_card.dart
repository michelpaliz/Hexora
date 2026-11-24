import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/utils/validation/email_validator.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/update_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';

/// Saves the business name/description. Defaults to [UpdateGroupUseCase].
typedef SaveBusinessIdentity = Future<void> Function(
    Group group, String name, String description);

/// Replaces the business profile image. Defaults to [UploadGroupPhotoUseCase].
typedef UploadBusinessPhoto = Future<void> Function(Group group, XFile file);

/// Picks an image for the business profile. Defaults to the gallery picker
/// used by the business settings editor.
typedef PickBusinessPhoto = Future<XFile?> Function();

/// Picks an invoice logo file (name + bytes). Defaults to the billing
/// profile editor's validated picker.
typedef PickInvoiceLogo = Future<({String name, List<int> bytes})?> Function(
    BuildContext context);

enum BusinessSetupState { checking, unknown, complete, attention, incomplete }

/// A missing piece of business configuration. [critical] issues block or
/// degrade invoicing; the rest are recommendations.
class BusinessSetupIssue {
  const BusinessSetupIssue(this.message, {required this.critical});
  final String message;
  final bool critical;
}

/// Business setup status derived only from saved data and the required billing
/// identity: legal name, NIF/CIF, fiscal address and invoice logo. Remaining
/// optional items are recommendations and do not block completion.
@visibleForTesting
({BusinessSetupState state, List<BusinessSetupIssue> issues})
    evaluateBusinessSetup({
  required Group group,
  required BillingProfile? profile,
  required bool profileLoaded,
  required bool isEs,
}) {
  final issues = <BusinessSetupIssue>[];
  bool blank(String? v) => (v ?? '').trim().isEmpty;
  if (!profileLoaded) {
    return (state: BusinessSetupState.checking, issues: issues);
  }
  if (profile == null) {
    issues.add(BusinessSetupIssue(
      isEs
          ? 'Faltan los datos fiscales para facturar.'
          : 'Fiscal details are missing for invoicing.',
      critical: true,
    ));
  } else {
    if (blank(profile.legalName)) {
      issues.add(BusinessSetupIssue(
          isEs ? 'Falta la razón social.' : 'The legal name is missing.',
          critical: true));
    }
    if (blank(profile.taxId)) {
      issues.add(BusinessSetupIssue(
          isEs ? 'Falta el NIF/CIF.' : 'The tax ID (NIF/CIF) is missing.',
          critical: true));
    }
    final addressIncomplete = [
      profile.addressStreet,
      profile.addressCity,
      profile.addressProvince,
      profile.addressPostalCode,
      profile.addressCountry,
    ].any(blank);
    if (addressIncomplete) {
      issues.add(BusinessSetupIssue(
          isEs
              ? 'Falta completar la dirección fiscal.'
              : 'The fiscal address is incomplete.',
          critical: true));
    }
    // The backend may know about requirements the client doesn't check.
    if (issues.isEmpty && profile.isComplete == false) {
      issues.add(BusinessSetupIssue(
          isEs
              ? 'Revisa los datos de facturación.'
              : 'Review the billing details.',
          critical: true));
    }
    if (blank(profile.logoUrl)) {
      issues.add(BusinessSetupIssue(
          isEs ? 'Añade el logotipo de facturación.' : 'Add an invoice logo.',
          critical: true));
    }
    if (blank(profile.website)) {
      issues.add(BusinessSetupIssue(
          isEs ? 'Añade la web del negocio.' : 'Add the business website.',
          critical: false));
    }
  }
  if (blank(group.displayPhotoUrl)) {
    issues.add(BusinessSetupIssue(
        isEs ? 'Añade una imagen de perfil.' : 'Add a profile image.',
        critical: false));
  }
  if (blank(group.description)) {
    issues.add(BusinessSetupIssue(
        isEs ? 'Añade una descripción.' : 'Add a description.',
        critical: false));
  }

  final critical = issues.where((i) => i.critical).length;
  final state = critical == 0
      ? BusinessSetupState.complete
      : profile == null
          ? BusinessSetupState.incomplete
          : BusinessSetupState.attention;
  // Critical issues first so the warning shows the most important one.
  issues.sort((a, b) => (b.critical ? 1 : 0) - (a.critical ? 1 : 0));
  return (state: state, issues: issues);
}

/// Home business identity card: compact summary by default, inline editing of
/// the quick fields on demand. Fiscal data stays read-only here and opens the
/// existing billing profile editor; images reuse the existing uploads.
class BusinessProfileCard extends StatefulWidget {
  const BusinessProfileCard({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.isEs,
    this.onOpenSettings,
    this.onOpenBillingProfile,
    this.billingApi,
    this.saveIdentity,
    this.uploadPhoto,
    this.pickPhoto,
    this.pickInvoiceLogo,
  });

  final Group group;
  final String? currentUserId;
  final bool isEs;
  final VoidCallback? onOpenSettings;

  /// Opens the existing billing profile (fiscal data) editor.
  final VoidCallback? onOpenBillingProfile;
  final BillingProfileApi? billingApi;
  final SaveBusinessIdentity? saveIdentity;
  final UploadBusinessPhoto? uploadPhoto;
  final PickBusinessPhoto? pickPhoto;
  final PickInvoiceLogo? pickInvoiceLogo;

  /// Same rule as the business settings screen: owner, admin or co-admin.
  /// The backend still enforces permissions on every request.
  static bool canEdit(Group group, String? userId) {
    if (userId == null) return false;
    if (group.ownerId == userId) return true;
    final role = group.userRoles[userId]?.toLowerCase().trim();
    return role == 'admin' || role == 'co-admin';
  }

  @override
  State<BusinessProfileCard> createState() => _BusinessProfileCardState();
}

class _BusinessProfileCardState extends State<BusinessProfileCard> {
  late final BillingProfileApi _api = widget.billingApi ?? BillingProfileApi();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _email = TextEditingController();

  BillingProfile? _profile;
  bool _profileLoaded = false;
  bool _profileError = false;
  String? _loadingFor;

  bool _editing = false;
  bool _saving = false;
  bool _photoBusy = false;
  bool _logoBusy = false;
  bool _showAllIssues = false;
  String? _saveError;

  bool get _es => widget.isEs;
  bool get _canEdit =>
      BusinessProfileCard.canEdit(widget.group, widget.currentUserId);

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _description, _website, _email]) {
      c.addListener(_onFieldChanged);
    }
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant BusinessProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      // Another business: never show the previous business's data.
      _editing = false;
      _saveError = null;
      _showAllIssues = false;
      _profile = null;
      _profileLoaded = false;
      _loadProfile();
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _website, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (_editing && mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final groupId = widget.group.id;
    _loadingFor = groupId;
    setState(() => _profileError = false);
    try {
      final profile = await _api.getByGroup(groupId);
      if (!mounted || _loadingFor != groupId) return;
      setState(() {
        _profile = profile;
        _profileLoaded = true;
      });
    } catch (_) {
      if (!mounted || _loadingFor != groupId) return;
      setState(() {
        _profileError = true;
        _profileLoaded = false;
      });
    }
  }

  // ── Edit session ──

  void _startEdit() {
    _name.text = widget.group.name;
    _description.text = widget.group.description;
    _website.text = _profile?.website ?? '';
    _email.text = _profile?.email ?? '';
    setState(() {
      _editing = true;
      _saveError = null;
    });
  }

  bool get _dirty =>
      _editing &&
      (_name.text.trim() != widget.group.name.trim() ||
          _description.text.trim() != widget.group.description.trim() ||
          _website.text.trim() != (_profile?.website ?? '').trim() ||
          _email.text.trim() != (_profile?.email ?? '').trim());

  void _cancel() => setState(() {
        _editing = false;
        _saveError = null;
      });

  static String? _normalizeWebsite(String raw) {
    final txt = raw.trim();
    if (txt.isEmpty) return null;
    final uri = Uri.tryParse(txt);
    if (uri != null && uri.hasScheme) return txt;
    if (txt.contains('.')) return 'https://$txt';
    return txt;
  }

  Future<void> _save() async {
    if (_saving || !_dirty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final group = widget.group;
    final name = _name.text.trim();
    final description = _description.text.trim();
    try {
      if (name != group.name.trim() ||
          description != group.description.trim()) {
        final save = widget.saveIdentity ??
            (g, n, d) => context
                .read<UpdateGroupUseCase>()
                .call(original: g, name: n, description: d);
        await save(group, name, description);
      }

      final profile = _profile;
      if (profile != null) {
        final websiteChanged =
            _website.text.trim() != (profile.website ?? '').trim();
        final emailChanged = _email.text.trim() != (profile.email ?? '').trim();
        BillingProfile? updated;
        if (emailChanged) {
          // Full upsert from the saved profile, like the billing editor; an
          // empty value is sent as null by toPayload().
          updated = await _api.upsert(profile.copyWith(
            email: _email.text.trim(),
            website: websiteChanged
                ? (_normalizeWebsite(_website.text) ?? '')
                : profile.website,
          ));
        } else if (websiteChanged) {
          updated = await _api.updateWebsite(
            groupId: group.id,
            website: _normalizeWebsite(_website.text) ?? '',
          );
        }
        if (updated != null && mounted && widget.group.id == group.id) {
          _profile = updated;
        }
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(_es ? 'Cambios guardados' : 'Changes saved'),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = _es
            ? 'No se pudieron guardar los cambios. Inténtalo de nuevo.'
            : 'Changes could not be saved. Try again.';
      });
    }
  }

  // ── Images ──

  Future<void> _changePhoto() async {
    if (!_canEdit || _photoBusy) return;
    final pick = widget.pickPhoto ??
        () => ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
              maxWidth: 1600,
            );
    final file = await pick();
    if (file == null || !mounted) return;
    setState(() => _photoBusy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final groupDomain = context.read<GroupDomain?>();
    try {
      final upload = widget.uploadPhoto ??
          (g, f) => context
              .read<UploadGroupPhotoUseCase>()
              .call(groupId: g.id, file: f);
      await upload(widget.group, file);
      // The backend may keep the same public URL while replacing the blob.
      // Evict both the old and refreshed URL so Flutter does not paint the
      // previous image from its global ImageProvider cache.
      final refreshed = groupDomain?.currentGroup;
      final urls = <String>{
        widget.group.displayPhotoUrl ?? '',
        if (refreshed != null) refreshed.displayPhotoUrl ?? '',
      }..removeWhere((url) => url.trim().isEmpty);
      for (final url in urls) {
        await AvatarUtils.evictNetworkImage(url);
      }
      messenger?.showSnackBar(SnackBar(
          content: Text(
              _es ? 'Imagen de perfil actualizada' : 'Profile image updated')));
    } catch (_) {
      messenger?.showSnackBar(SnackBar(
          content: Text(_es
              ? 'No se pudo actualizar la imagen'
              : 'The image could not be updated')));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _changeLogo() async {
    if (!_canEdit || _logoBusy || _profile == null) return;
    final pick = widget.pickInvoiceLogo ??
        (ctx) async {
          final selected = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            withData: true,
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg'],
          );
          final file = selected?.files.single;
          final bytes = file?.bytes;
          if (file == null ||
              bytes == null ||
              bytes.isEmpty ||
              file.size > 15 * 1024 * 1024) {
            return null;
          }
          return (name: file.name, bytes: bytes.toList());
        };
    final picked = await pick(context);
    if (picked == null || !mounted) return;
    final groupId = widget.group.id;
    setState(() => _logoBusy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      // Invoice branding only: the profile image is never touched.
      final updated = await _api.uploadLogo(
        groupId: groupId,
        filename: picked.name,
        bytes: picked.bytes,
      );
      if (mounted && widget.group.id == groupId) {
        setState(() => _profile = updated);
      }
      messenger?.showSnackBar(SnackBar(
          content: Text(_es
              ? 'Logotipo de facturación actualizado'
              : 'Invoice logo updated')));
    } catch (_) {
      messenger?.showSnackBar(SnackBar(
          content: Text(_es
              ? 'No se pudo subir el logotipo'
              : 'The logo could not be uploaded')));
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final setup = evaluateBusinessSetup(
      group: widget.group,
      profile: _profile,
      profileLoaded: _profileLoaded,
      isEs: _es,
    );
    final state = _profileError ? BusinessSetupState.unknown : setup.state;

    return PopScope(
      // Leaving with unsaved edits asks first, like the settings editor.
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) {
          _cancel();
          navigator.maybePop();
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          key: const ValueKey('business-profile-card'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .7)),
          ),
          child: LayoutBuilder(builder: (context, c) {
            final width = c.maxWidth;
            final desktop = width >= 960;
            final tablet = !desktop && width >= 600;
            // No hover on touch devices: keep the camera badge visible.
            final touch = !desktop ||
                const [TargetPlatform.android, TargetPlatform.iOS]
                    .contains(defaultTargetPlatform);

            final imageWidth =
                desktop ? (width >= 1180 ? 210.0 : 184.0) : 168.0;
            final centreWidth = desktop
                ? width - imageWidth - 20 - 24 - 236
                : tablet
                    ? width - imageWidth - 18
                    : width;
            final info = _editing
                ? _editForm()
                : _infoGrid(
                    columns: centreWidth >= 560
                        ? 3
                        : centreWidth >= 340
                            ? 2
                            : 1);
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _nameAndDescription(),
                const SizedBox(height: 12),
                info,
              ],
            );
            final config =
                _configPanel(state, setup.issues, horizontal: tablet);

            /// The image fills the height set by the text/config content
            /// (never less than [minHeight]) instead of making the card
            /// taller. A Stack keeps this free of intrinsic measurements.
            Widget besideImage({
              required double imageWidth,
              required double gap,
              required Widget content,
            }) {
              return Stack(children: [
                Padding(
                  padding: EdgeInsets.only(left: imageWidth + gap),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 150),
                    child: content,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: imageWidth,
                  child: _image(showBadge: touch),
                ),
              ]);
            }

            if (desktop) {
              return besideImage(
                imageWidth: imageWidth,
                gap: 20,
                content: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: text,
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 236,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: config,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (tablet) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  besideImage(
                    imageWidth: imageWidth,
                    gap: 18,
                    content: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  config,
                ],
              );
            }
            // Mobile: wide image on top, content stacked below.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 150, child: _image(showBadge: true)),
                const SizedBox(height: 12),
                text,
                const SizedBox(height: 14),
                config,
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_es ? 'Descartar cambios' : 'Discard changes'),
        content: Text(_es
            ? 'Tienes cambios sin guardar. ¿Deseas descartarlos?'
            : 'You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_es ? 'Cancelar' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_es ? 'Descartar' : 'Discard')),
        ],
      ),
    );
    return result == true;
  }

  /// Large rounded business image. Fills the constraints its parent gives it
  /// (cropped with BoxFit.cover, never distorted); the fallback keeps the
  /// same size so the area never collapses.
  Widget _image({required bool showBadge}) {
    final cs = Theme.of(context).colorScheme;
    final url = widget.group.displayPhotoUrl;
    final hasImage = url != null && url.isNotEmpty;
    final fallback = Image.asset(
      HexoraBrandAssets.defaultBusinessImage,
      key: const ValueKey('business-default-image'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    final image = Container(
      key: const ValueKey('business-profile-image'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color.alphaBlend(cs.primary.withValues(alpha: .08), cs.surface),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .7)),
      ),
      // A broken or unreachable image falls back to the placeholder.
      child: hasImage
          ? Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
    if (!_canEdit) return image;
    return _PhotoEditTarget(
      busy: _photoBusy,
      alwaysShowBadge: showBadge,
      tooltip: _es ? 'Cambiar imagen del negocio' : 'Change business image',
      onTap: _changePhoto,
      child: image,
    );
  }

  TextStyle get _nameStyle => TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 17.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  Widget _nameAndDescription() {
    final cs = Theme.of(context).colorScheme;
    final name = widget.group.name.trim();
    final description = widget.group.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? (_es ? 'Tu negocio' : 'Your business') : name,
          key: const ValueKey('business-profile-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _nameStyle,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 12.5, height: 1.4),
          ),
        ],
      ],
    );
  }

  /// Fiscal and contact data as a compact labelled grid: secondary to the
  /// name and status, but easy to scan. Long values truncate with a tooltip.
  Widget _infoGrid({required int columns}) {
    final cs = Theme.of(context).colorScheme;
    if (!_profileLoaded && !_profileError) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: cs.primary),
        ),
      );
    }
    final p = _profile;
    String join(List<String?> parts, [String sep = ', ']) =>
        parts.map((e) => (e ?? '').trim()).where((e) => e.isNotEmpty).join(sep);
    final legalName = (p?.legalName ?? '').trim();
    // Don't repeat the legal name when it matches the commercial name.
    final showLegalName = legalName.isNotEmpty &&
        legalName.toLowerCase() != widget.group.name.trim().toLowerCase();
    final fields = <(String, String?)>[
      if (p == null || showLegalName)
        (_es ? 'Nombre fiscal' : 'Legal name', p == null ? null : legalName),
      ('NIF/CIF', p?.taxId),
      (
        _es ? 'Dirección fiscal' : 'Fiscal address',
        p == null
            ? null
            : join([
                p.addressStreet,
                join([p.addressPostalCode, p.addressCity], ' '),
                p.addressProvince,
              ]),
      ),
      (_es ? 'Sitio web' : 'Website', p?.website),
      (_es ? 'Correo electrónico' : 'Email', p?.email),
    ];

    Widget cell((String, String?) field) {
      final (label, raw) = field;
      final value = (raw ?? '').trim();
      final missing = value.isEmpty;
      final text = Text(
        missing ? (_es ? 'No indicado' : 'Not set') : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: missing
              ? cs.onSurfaceVariant.withValues(alpha: .7)
              : cs.onSurface,
          fontStyle: missing ? FontStyle.italic : FontStyle.normal,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          missing
              ? text
              : Tooltip(
                  message: value,
                  waitDuration: const Duration(milliseconds: 400),
                  child: text,
                ),
        ],
      );
    }

    final fiscalAction = _canEdit && widget.onOpenBillingProfile != null
        ? InkWell(
            key: const ValueKey('business-edit-fiscal'),
            onTap: widget.onOpenBillingProfile,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                p == null
                    ? (_es
                        ? 'Configurar datos fiscales'
                        : 'Set up fiscal details')
                    : (_es ? 'Editar datos fiscales' : 'Edit fiscal details'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary),
              ),
            ),
          )
        : null;

    final cells = <Widget>[
      for (final field in fields) cell(field),
      // Fiscal data opens the existing validated billing profile editor.
      if (fiscalAction != null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Align(alignment: Alignment.centerLeft, child: fiscalAction),
        ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += columns) {
      final slice = cells.skip(i).take(columns).toList();
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: 20),
            Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
          ],
        ],
      ));
    }

    return Column(
      key: const ValueKey('business-profile-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          row,
        ],
      ],
    );
  }

  InputDecoration _input(String label, {String? helper}) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      isDense: true,
      filled: true,
      fillColor:
          Color.alphaBlend(cs.primary.withValues(alpha: .06), cs.surface),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      labelStyle: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
      border: border(cs.outlineVariant),
      enabledBorder: border(cs.outlineVariant),
      focusedBorder: border(cs.primary, 1.4),
      disabledBorder: border(cs.outlineVariant.withValues(alpha: .5)),
    );
  }

  Widget _editForm() {
    final cs = Theme.of(context).colorScheme;
    final hasProfile = _profile != null;
    final noProfileHelp = _es
        ? 'Disponible cuando configures los datos fiscales.'
        : 'Available once fiscal details are set up.';
    const style = TextStyle(fontSize: 13);
    final fields = <Widget>[
      TextFormField(
        key: const ValueKey('business-edit-name'),
        controller: _name,
        enabled: !_saving,
        style: style,
        maxLength: 50,
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        decoration: _input(_es ? 'Nombre comercial' : 'Business name')
            .copyWith(counterText: ''),
        validator: (v) => (v ?? '').trim().isEmpty
            ? (_es ? 'El nombre es obligatorio' : 'The name is required')
            : null,
      ),
      TextFormField(
        key: const ValueKey('business-edit-description'),
        controller: _description,
        enabled: !_saving,
        style: style,
        minLines: 1,
        maxLines: 3,
        maxLength: 200,
        decoration: _input(_es ? 'Descripción' : 'Description')
            .copyWith(counterText: ''),
        // Same rule as the business settings editor.
        validator: (v) => (v ?? '').trim().isEmpty
            ? (_es
                ? 'La descripción es obligatoria'
                : 'The description is required')
            : null,
      ),
      TextFormField(
        key: const ValueKey('business-edit-website'),
        controller: _website,
        enabled: !_saving && hasProfile,
        style: style,
        keyboardType: TextInputType.url,
        decoration: _input('Web', helper: hasProfile ? null : noProfileHelp),
        validator: (v) {
          final txt = (v ?? '').trim();
          if (txt.isEmpty) return null;
          final uri = Uri.tryParse(txt);
          final ok = (uri != null && (uri.hasScheme || uri.host.isNotEmpty)) ||
              txt.contains('.');
          return ok ? null : (_es ? 'URL no válida' : 'Invalid URL');
        },
      ),
      TextFormField(
        key: const ValueKey('business-edit-email'),
        controller: _email,
        enabled: !_saving && hasProfile,
        style: style,
        keyboardType: TextInputType.emailAddress,
        decoration: _input(_es ? 'Email de contacto' : 'Contact email',
            helper: hasProfile ? null : noProfileHelp),
        validator: (v) {
          final txt = (v ?? '').trim();
          if (txt.isEmpty) return null;
          return isLikelyValidEmail(txt)
              ? null
              : (_es ? 'Email no válido' : 'Invalid email');
        },
      ),
    ];
    return Form(
      key: _formKey,
      child: LayoutBuilder(builder: (context, c) {
        final twoCol = c.maxWidth >= 520;
        Widget grid() {
          if (!twoCol) {
            return Column(children: [
              for (final (i, f) in fields.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                f,
              ],
            ]);
          }
          Widget pair(Widget a, Widget b) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: 10),
                  Expanded(child: b),
                ],
              );
          return Column(children: [
            pair(fields[0], fields[2]),
            const SizedBox(height: 10),
            pair(fields[1], fields[3]),
          ]);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            grid(),
            const SizedBox(height: 10),
            Text(
              _es
                  ? 'La razón social, el NIF/CIF y la dirección fiscal se editan en los datos fiscales.'
                  : 'Legal name, tax ID and fiscal address are edited in the fiscal details.',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(_saveError!,
                  key: const ValueKey('business-edit-error'),
                  style: TextStyle(fontSize: 12, color: cs.error)),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('business-edit-cancel'),
                  onPressed: _saving ? null : _cancel,
                  child: Text(_es ? 'Cancelar' : 'Cancel'),
                ),
                FilledButton.icon(
                  key: const ValueKey('business-edit-save'),
                  onPressed: _saving || !_dirty ? null : _save,
                  icon: _saving
                      ? SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Icon(LucideIcons.check, size: 16),
                  label: Text(_es ? 'Guardar cambios' : 'Save changes'),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _statusPill(BusinessSetupState state) {
    final cs = Theme.of(context).colorScheme;
    const green = Color(0xFF17B26A);
    const amber = Color(0xFFB54708);
    final (IconData icon, String label, Color color) = switch (state) {
      BusinessSetupState.checking => (
          LucideIcons.loader,
          _es ? 'Comprobando configuración…' : 'Checking setup…',
          cs.onSurfaceVariant
        ),
      BusinessSetupState.unknown => (
          LucideIcons.circleHelp,
          _es ? 'Estado no disponible' : 'Status unavailable',
          cs.onSurfaceVariant
        ),
      BusinessSetupState.complete => (
          LucideIcons.circleCheck,
          _es ? 'Configuración completa' : 'Setup complete',
          green
        ),
      BusinessSetupState.attention => (
          LucideIcons.triangleAlert,
          _es ? 'Requiere atención' : 'Needs attention',
          amber
        ),
      BusinessSetupState.incomplete => (
          LucideIcons.triangleAlert,
          _es ? 'Configuración incompleta' : 'Setup incomplete',
          amber
        ),
    };
    return Container(
      key: const ValueKey('business-setup-status'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  /// Status, the most important pending item, invoice branding and the card
  /// actions, grouped away from the fiscal data.
  Widget _configPanel(
    BusinessSetupState state,
    List<BusinessSetupIssue> issues, {
    required bool horizontal,
  }) {
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [Flexible(child: _statusPill(state))]),
        if (_warning(issues, state) case final warning?) ...[
          const SizedBox(height: 8),
          warning,
        ],
      ],
    );
    final logo = _logoRow();
    final actions = _editing ? null : _actions();
    if (horizontal) {
      return Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300), child: status),
          SizedBox(width: 236, child: logo),
          if (actions != null) SizedBox(width: 236, child: actions),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        status,
        const SizedBox(height: 12),
        logo,
        if (actions != null) ...[
          const SizedBox(height: 12),
          actions,
        ],
      ],
    );
  }

  static const _compactButton = ButtonStyle(
    visualDensity: VisualDensity.standard,
    minimumSize: WidgetStatePropertyAll(Size(0, 36)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)))),
    textStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
  );

  /// Invoice branding: its own thumbnail, separate from the profile image.
  Widget _logoRow() {
    final cs = Theme.of(context).colorScheme;
    final p = _profile;
    final url = ((p?.logoPreviewUrl ?? '').trim().isNotEmpty
            ? p!.logoPreviewUrl
            : p?.logoUrl)
        ?.trim();
    final hasLogo = (p?.logoUrl ?? '').trim().isNotEmpty;
    final placeholder =
        Icon(LucideIcons.fileImage, size: 16, color: cs.onSurfaceVariant);
    return Row(children: [
      Container(
        key: const ValueKey('business-logo-thumbnail'),
        width: 34,
        height: 34,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color:
              Color.alphaBlend(cs.primary.withValues(alpha: .05), cs.surface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .7)),
        ),
        alignment: Alignment.center,
        child: _logoBusy
            ? SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: cs.primary))
            : hasLogo && url != null && url.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => placeholder,
                    ),
                  )
                : placeholder,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_es ? 'Logo de facturación' : 'Invoice logo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            Text(
              !_profileLoaded
                  ? '—'
                  : hasLogo
                      ? (_es ? 'Configurado' : 'Configured')
                      : (_es ? 'Sin configurar' : 'Not set'),
              key: const ValueKey('business-logo-status'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
          ],
        ),
      ),
      if (_canEdit && _profileLoaded && _profile != null)
        OutlinedButton(
          key: const ValueKey('business-logo-change'),
          onPressed: _logoBusy ? null : _changeLogo,
          style: _compactButton,
          child: Text(hasLogo
              ? (_es ? 'Cambiar' : 'Change')
              : (_es ? 'Añadir' : 'Add')),
        ),
    ]);
  }

  /// Keep profile editing prominent and business settings easy to discover.
  Widget _actions() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_profileError)
            TextButton.icon(
              key: const ValueKey('business-profile-retry'),
              onPressed: _loadProfile,
              style: _compactButton,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text(_es ? 'Reintentar' : 'Retry'),
            ),
          if (_canEdit)
            FilledButton.icon(
              key: const ValueKey('business-edit'),
              onPressed: _profileLoaded || _profileError ? _startEdit : null,
              style: _compactButton,
              icon: const Icon(LucideIcons.pencil, size: 14),
              label: Text(_es ? 'Editar perfil' : 'Edit profile'),
            ),
          if (_canEdit && widget.onOpenSettings != null)
            const SizedBox(height: 8),
          if (widget.onOpenSettings != null)
            OutlinedButton.icon(
              key: const ValueKey('business-open-settings'),
              onPressed: widget.onOpenSettings,
              style: _compactButton,
              icon: const Icon(LucideIcons.settings, size: 14),
              label: Text(_es ? 'Configurar negocio' : 'Business settings'),
            ),
        ]);
  }

  /// Compact pending-configuration note under the status: the most important
  /// critical issue, a way to resolve it and the rest on demand. Optional
  /// recommendations never show here.
  Widget? _warning(List<BusinessSetupIssue> issues, BusinessSetupState state) {
    if (_editing) return null;
    if (state != BusinessSetupState.attention &&
        state != BusinessSetupState.incomplete) {
      return null;
    }
    final critical = issues.where((i) => i.critical).toList();
    if (critical.isEmpty) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFFEC84B) : const Color(0xFF93370D);
    final shown = _showAllIssues ? critical : critical.take(1).toList();
    TextStyle link = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ink,
        decoration: TextDecoration.underline,
        decorationColor: ink);
    return Container(
      key: const ValueKey('business-setup-warning'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF79009).withValues(alpha: isDark ? .12 : .07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final issue in shown)
            Text(issue.message,
                style: TextStyle(fontSize: 12, color: ink, height: 1.4)),
          const SizedBox(height: 4),
          Wrap(spacing: 12, children: [
            if (_canEdit && widget.onOpenBillingProfile != null)
              GestureDetector(
                key: const ValueKey('business-setup-fix'),
                onTap: widget.onOpenBillingProfile,
                child: Text(_es ? 'Completar' : 'Complete', style: link),
              ),
            if (critical.length > 1)
              GestureDetector(
                key: const ValueKey('business-setup-more'),
                onTap: () => setState(() => _showAllIssues = !_showAllIssues),
                child: Text(
                  _showAllIssues
                      ? (_es ? 'Ver menos' : 'Show less')
                      : (_es
                          ? 'Ver ${critical.length - 1} más'
                          : 'Show ${critical.length - 1} more'),
                  style: link,
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Profile image with a camera overlay on hover/focus for authorised users.
class _PhotoEditTarget extends StatefulWidget {
  const _PhotoEditTarget({
    required this.child,
    required this.onTap,
    required this.tooltip,
    required this.busy,
    this.alwaysShowBadge = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool busy;

  /// Touch layouts have no hover, so the camera badge stays visible.
  final bool alwaysShowBadge;

  @override
  State<_PhotoEditTarget> createState() => _PhotoEditTargetState();
}

/// Business image with a small camera badge in the bottom-right corner:
/// shown on hover/focus with a pointer, always on touch layouts.
class _PhotoEditTargetState extends State<_PhotoEditTarget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final showBadge = widget.alwaysShowBadge || _hover;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          onShowFocusHighlight: (v) => setState(() => _hover = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => widget.busy ? null : widget.onTap()),
          },
          child: GestureDetector(
            key: const ValueKey('business-photo-edit'),
            onTap: widget.busy ? null : widget.onTap,
            child: Stack(fit: StackFit.passthrough, children: [
              widget.child,
              if (widget.busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .32),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 8,
                child: AnimatedOpacity(
                  key: const ValueKey('business-photo-badge'),
                  duration: const Duration(milliseconds: 120),
                  opacity: showBadge && !widget.busy ? 1 : 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera,
                        size: 15, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
