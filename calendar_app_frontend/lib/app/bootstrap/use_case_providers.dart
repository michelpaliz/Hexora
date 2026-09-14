import 'package:hexora/data/auth/auth/auth_services/auth_provider.dart';
import 'package:hexora/data/config/api_constants.dart';
import 'package:hexora/data/group_management/group/domain/group_domain.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/create_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/invite_members_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/search_users_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/update_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/data/group_management/invite/repository/invite_repository.dart';
import 'package:hexora/data/user/domain/user_domain.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> useCaseProviders = [
  Provider<CreateGroupUseCase>(
    create: (c) => CreateGroupUseCase(
      c.read<GroupDomain>(),
      c.read<UserDomain>(),
    ),
  ),
  Provider<InviteMembersUseCase>(
    create: (c) => InviteMembersUseCase(
      c.read<InvitationRepository>(),
      c.read<AuthProvider>(),
    ),
  ),
  Provider<UploadGroupPhotoUseCase>(
    create: (c) => UploadGroupPhotoUseCase(
      c.read<GroupDomain>(),
      c.read<AuthProvider>(),
      c.read<UserDomain>(),
    ),
  ),
  // ✅ NEW: provide UpdateGroupUseCase
  Provider<UpdateGroupUseCase>(
    create: (c) =>
        UpdateGroupUseCase(c.read<GroupDomain>(), c.read<UserDomain>()),
  ),
  Provider<SearchUsersUseCase>(
    create: (c) => SearchUsersUseCase(
      c.read<http.Client>(), // ← shared client
      c.read<AuthProvider>(),
      ApiConstants.baseUrl, // ← pass baseUrl here
    ),
  ),
];
