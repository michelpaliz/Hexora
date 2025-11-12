import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/models/group_data_body.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/buttons/save_group_button.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EditGroupData extends StatefulWidget {
  final Group group;
  final List<User> users;

  const EditGroupData({
    required this.group,
    required this.users,
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
    final vm = context.read<GroupEditorViewModel>(); // ✅ read VM directly

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.editGroup,
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: GroupDataBody(
        nameController: _nameC,
        descController: _descC,
        title: l.groupData,
        bottomSection: SaveGroupButton(
          controller: vm,
        ),
      ),
    );
  }
}
