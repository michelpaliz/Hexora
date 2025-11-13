// feature_providers.dart (or a new file)
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/common/ui_messenger.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/update_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/service/vm_group_editor_port.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// your UI messenger (can be a no-op for now)
class NoopUiMessenger implements UiMessenger {
  @override
  Future<void> showError(String m) async {}
  @override
  void showSnack(String m) {}

  @override
  void pop() {}
}

final List<SingleChildWidget> editorProviders = [
  // Provide the VM (needs auth + use cases).
  ChangeNotifierProvider<GroupEditorViewModel>(
    create: (ctx) => GroupEditorViewModel(
      currentUser: ctx.read<AuthProvider>().currentUser!,
      ui: NoopUiMessenger(), // you can override with a context-aware messenger at screen level
      createGroup: ctx.read<CreateGroupUseCase>(),
      inviteMembers: ctx.read<InviteMembersUseCase>(),
      uploadPhoto: ctx.read<UploadGroupPhotoUseCase>(),
      searchUsersUseCase: ctx.read<SearchUsersUseCase>(),
      updateGroup: ctx.read<UpdateGroupUseCase>(),
    ),
  ),

  // Build the Port from the VM (important: ProxyProvider so the order is guaranteed)
  ProxyProvider<GroupEditorViewModel, IGroupEditorPort>(
    update: (_, vm, __) => VmGroupEditorPort(vm),
  ),
];
