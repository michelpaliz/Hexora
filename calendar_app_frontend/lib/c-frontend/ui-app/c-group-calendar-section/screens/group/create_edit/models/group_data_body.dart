import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_description_field.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_name_field.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/widgets/images/group_image.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/card_surface.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class GroupDataBody extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;

  /// If you want to push changes into your VM live
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onDescChanged;

  /// Image picked callback
  final ValueChanged<XFile>? onPicked;

  /// NEW: existing image url (for edit mode)
  final String? initialImageUrl;

  /// Optional section rendered after the description card (e.g., save button)
  final Widget? bottomSection;

  /// Optional page title
  final String? title;

  /// Max characters (shown in the localized header labels)
  final int titleMaxChars;
  final int descMaxChars;

  const GroupDataBody({
    super.key,
    required this.nameController,
    required this.descController,
    this.onNameChanged,
    this.onDescChanged,
    this.onPicked,
    this.initialImageUrl,
    this.bottomSection,
    this.title,
    this.titleMaxChars = 50,
    this.descMaxChars = 200,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: t.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Image section with compact header tint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                GroupImage(
                  imageUrl:
                      initialImageUrl, // 👈 show existing group photo if any
                  onPicked: onPicked,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title (name) card
          ThemedCard(
            radius: 14,
            elevation: 0.5,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔈 Localized: "Título (máximo {maxChar} caracteres)"
                Text(
                  l.title(titleMaxChars),
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                GroupNameField(
                  controller: nameController,
                  onChanged: onNameChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Description card
          ThemedCard(
            radius: 14,
            elevation: 0.5,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔈 Localized: "Descripción (máximo {maxChar} caracteres)"
                Text(
                  l.description(descMaxChars),
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                GroupDescriptionField(
                  controller: descController,
                  onChanged: onDescChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (bottomSection != null) bottomSection!,
        ],
      ),
    );
  }
}
