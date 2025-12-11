import 'package:hexora/a-models/user_model/user.dart';
import 'package:flutter/material.dart';

typedef SasFetcher = Future<String?> Function(String blobName);

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.user,
    required this.fetchReadSas,
    this.radius = 30,
    this.placeholder = const AssetImage('assets/images/default_profile.png'),
  });

  final User user;
  final SasFetcher fetchReadSas;
  final double radius;
  final ImageProvider placeholder;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _sasUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ensureSas();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.photoUrl != widget.user.photoUrl ||
        oldWidget.user.photoBlobName != widget.user.photoBlobName) {
      _sasUrl = null;
      _ensureSas();
    }
  }

  Future<void> _ensureSas() async {
    final url = widget.user.photoUrl ?? '';
    final blob = widget.user.photoBlobName ?? '';

    // If we already have a public or SAS URL, just use it.
    if (url.isNotEmpty) {
      if (mounted) setState(() => _sasUrl = url);
      return;
    }

    // Otherwise, try to fetch a read SAS (only if we have a blob name).
    if (blob.isEmpty || _loading) return;

    _loading = true;
    try {
      final sas = await widget.fetchReadSas(blob);
      if (!mounted) return;
      setState(() => _sasUrl = sas);
    } finally {
      _loading = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final useUrl = _sasUrl;

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: (useUrl != null && useUrl.isNotEmpty)
          ? NetworkImage(useUrl)
          : widget.placeholder,
      onBackgroundImageError: (_, __) {
        if (mounted) setState(() => _sasUrl = null);
      },
      child: null,
    );
  }
}
