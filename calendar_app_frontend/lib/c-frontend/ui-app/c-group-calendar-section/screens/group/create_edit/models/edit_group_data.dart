import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/models/group_data_body.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/widgets/buttons/save_group_button.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EditGroupData extends StatefulWidget {
  final Group group;
  final List<User> users;
  final bool showAppBar;

  const EditGroupData({
    required this.group,
    required this.users,
    this.showAppBar = true,
    Key? key,
  }) : super(key: key);

  @override
  State<EditGroupData> createState() => _EditGroupDataState();
}

class _EditGroupDataState extends State<EditGroupData> {
  late TextEditingController _nameC;
  late TextEditingController _descC;
  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.group.name);
    _descC = TextEditingController(text: widget.group.description);

    // Seed VM with the original group AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<GroupEditorViewModel>();
      vm.enterEditFrom(widget.group);
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final vm = context.read<GroupEditorViewModel>(); // ensure Provider is above

    final heading = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        l.editGroup,
        style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final form = GroupDataBody(
      nameController: _nameC,
      descController: _descC,
      title: l.groupData,
      // ✅ Keep VM in sync while editing
      initialImageUrl: widget.group.photoUrl,
      onNameChanged: vm.setName,
      onDescChanged: vm.setDescription,
      onPicked: vm.setImage,
      bottomSection: const SizedBox.shrink(),
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                l.editGroup,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: widget.showAppBar
          ? form
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                heading,
                form,
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SaveGroupButton(controller: vm),
      ),
    );
  }
}
