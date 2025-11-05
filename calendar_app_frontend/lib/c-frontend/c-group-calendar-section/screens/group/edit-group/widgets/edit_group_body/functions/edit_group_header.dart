import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/edit-group/widgets/form/group_description_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/edit-group/widgets/form/group_image_section.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/edit-group/widgets/form/group_name_field.dart';
import 'package:hexora/f-themes/shape/solid/solid_header.dart';
import 'package:image_picker/image_picker.dart';

class EditGroupHeader extends StatelessWidget {
  final String imageURL;
  final XFile? selectedImage;
  final VoidCallback onPickImage;
  final String groupName;
  final void Function(String) onNameChange;
  final TextEditingController descriptionController;

  const EditGroupHeader({
    Key? key,
    required this.imageURL,
    this.selectedImage,
    required this.onPickImage,
    required this.groupName,
    required this.onNameChange,
    required this.descriptionController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only the top header (image area) has the solid color background.
    // The form fields live on the normal page surface.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header area with solid color + image picker
        Stack(
          children: [
            const SolidHeader(height: 150),
            // Position your image section inside the header area
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: GroupImageSection(
                imageURL: imageURL,
                selectedImage: selectedImage,
                onPickImage: onPickImage,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Form fields on normal surface (no solid background)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupNameField(
                groupName: groupName,
                onNameChange: onNameChange,
              ),
              GroupDescriptionField(
                descriptionController: descriptionController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
