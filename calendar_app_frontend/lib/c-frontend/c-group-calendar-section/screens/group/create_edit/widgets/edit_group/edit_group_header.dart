import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_description_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_name_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/images/group_image.dart';
import 'package:hexora/f-themes/shapes/solid/solid_header.dart';
import 'package:image_picker/image_picker.dart';

class EditGroupHeader extends StatelessWidget {
  /// NEW: matches GroupImage API
  final String? imageUrl;
  final bool isUploading;
  final Future<void> Function(XFile file)? onPicked;
  final Future<void> Function()? onRemove;

  /// Text-field controllers
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const EditGroupHeader({
    Key? key,
    required this.nameController,
    required this.descriptionController,
    this.imageUrl,
    this.isUploading = false,
    this.onPicked,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            const SolidHeader(height: 150),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: GroupImage(
                imageUrl: imageUrl,
                isUploading: isUploading,
                onPicked: onPicked,
                onRemove: onRemove,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupNameField(controller: nameController),
              const SizedBox(height: 12),
              GroupDescriptionField(controller: descriptionController),
            ],
          ),
        ),
      ],
    );
  }
}
