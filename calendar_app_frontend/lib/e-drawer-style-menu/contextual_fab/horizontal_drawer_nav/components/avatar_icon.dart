import 'package:flutter/material.dart';

class AvatarIcon extends StatelessWidget {
  final String? photoUrl;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const AvatarIcon({
    super.key,
    required this.photoUrl,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 28.0 : 24.0;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Container(
        width: size + 2,
        height: size + 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          image: DecorationImage(
            image: NetworkImage(photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Icon(
      Icons.person_rounded,
      size: size,
      color: isSelected ? activeColor : inactiveColor,
    );
  }
}
