import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MyHeaderDrawer extends StatefulWidget {
  const MyHeaderDrawer({super.key});

  @override
  State<MyHeaderDrawer> createState() => _MyHeaderDrawerState();
}

class _MyHeaderDrawerState extends State<MyHeaderDrawer> {
  XFile? _selectedImage;
  User? _currentUser = User.empty();
  late UserDomain _userDomain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userDomain = Provider.of<UserDomain>(context);
    _currentUser = _userDomain.user;
  }

  /// Fetch a read SAS URL for a given blob name (used only when avatarsArePublic == false)
  Future<String?> _fetchReadSas(String blobName) async {
    final auth = context.read<AuthProvider>();
    final accessToken = auth.lastToken;
    if (accessToken == null) return null;

    final resp = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/blob/read-sas?blobName=${Uri.encodeComponent(blobName)}'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (resp.statusCode != 200) {
      debugPrint('⚠️ Failed to get read SAS: ${resp.statusCode} ${resp.body}');
      return null;
    }
    return (jsonDecode(resp.body) as Map<String, dynamic>)['url'] as String;
  }

  /// Pick an image and start upload
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    _selectedImage = picked;
    await _uploadProfileImageToBackend(File(picked.path));
  }

  /// Upload using the shared helper + commit the avatar on the backend
  Future<void> _uploadProfileImageToBackend(File file) async {
    if (!mounted) return;

    try {
      final auth = context.read<AuthProvider>();
      final accessToken = auth.lastToken;
      if (accessToken == null || _currentUser == null) return;

      // 1) Upload to Azure (shared helper handles SAS + PUT + public/read URL)
      final result = await uploadImageToAzure(
        scope: 'users',
        file: file,
        accessToken: accessToken,
      );

      // 2) Commit on backend
      final commitResp = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blobName': result.blobName}),
      );

      final updatedUserJson = (commitResp.statusCode == 200)
          ? jsonDecode(commitResp.body) as Map<String, dynamic>
          : null;

      final committedPhotoUrl = updatedUserJson?['photoUrl'] ?? result.photoUrl;
      final committedBlobName =
          updatedUserJson?['photoBlobName'] ?? result.blobName;

      if (!mounted) return;

      setState(() {
        _currentUser = _currentUser?.copyWith(
          photoUrl: committedPhotoUrl,
          photoBlobName: committedBlobName,
        );
      });
      _userDomain.setCurrentUser(_currentUser!);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final headerBackgroundColor = ThemeColors.cardBg(context).withOpacity(0.95);
    final nameTextColor = ThemeColors.textPrimary(context);
    final emailTextColor = ThemeColors.textPrimary(context).withOpacity(0.75);

    return Container(
      color: headerBackgroundColor,
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: (_currentUser != null)
                ? UserAvatar(
                    user: _currentUser!,
                    // If avatarsArePublic == true, UserAvatar uses public URL.
                    // If false, it will call this to fetch a short-lived SAS.
                    fetchReadSas: _fetchReadSas,
                    radius: 30,
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor: cs.secondary.withOpacity(0.15),
                    child: Icon(Icons.person, color: cs.secondary),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentUser?.name ?? 'Guest',
            style: t.titleLarge.copyWith(
              color: nameTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.email ?? '',
            style: t.bodySmall.copyWith(
              color: emailTextColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
