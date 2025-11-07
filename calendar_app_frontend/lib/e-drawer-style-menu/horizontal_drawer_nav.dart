import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HorizontalDrawerNav extends StatefulWidget {
  const HorizontalDrawerNav({
    super.key,
    this.centerGapWidth = 80, // ~56 FAB + margins/notch
  });

  final double centerGapWidth;

  @override
  State<HorizontalDrawerNav> createState() => _HorizontalDrawerNavState();
}

class _HorizontalDrawerNavState extends State<HorizontalDrawerNav> {
  int _selectedIndex = 0;

  final List<_NavItemData> _items = const [
    _NavItemData(
      icon: Iconsax.home_1, // Home
      route: AppRoutes.homePage,
      semanticLabel: 'Home',
    ),
    _NavItemData(
      icon: Iconsax.calendar_1, // Agenda
      route: AppRoutes.agenda,
      semanticLabel: 'Agenda',
    ),
    _NavItemData(
      icon: Iconsax.notification, // Notifications
      route: AppRoutes.showNotifications,
      semanticLabel: 'Notifications',
    ),
    _NavItemData(
      icon: Iconsax.user, // Profile (fallback if no avatar)
      route: AppRoutes.profileDetails,
      semanticLabel: 'Profile',
      isProfile: true,
    ),
  ];

  static const Map<String, int> _routeIndex = {
    AppRoutes.showGroups: 0,
    AppRoutes.agenda: 1,
    AppRoutes.showNotifications: 2,
    AppRoutes.profileDetails: 3,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context)?.settings.name;
    if (current != null && _routeIndex.containsKey(current)) {
      _selectedIndex = _routeIndex[current]!;
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    final route = _items[index].route;

    if (route == AppRoutes.showNotifications) {
      final user = context.read<UserDomain>().user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user available for notifications')),
        );
        return;
      }
      Navigator.pushReplacementNamed(context, route, arguments: user);
      return;
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final inactiveColor =
        isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

    final user = context.watch<UserDomain>().user;
    final mid = (_items.length / 2).floor();

    // Get bottom safe area padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Container(
          height: 56 + bottomPadding,
          width: double.infinity,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: (isDark ? AppDarkColors.background : AppColors.background)
                .withOpacity(0.96),
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.15),
                width: 1.0,
              ),
            ),
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < mid; i++)
                  _buildButton(i, user, activeColor, inactiveColor),
                SizedBox(width: widget.centerGapWidth),
                for (var i = mid; i < _items.length; i++)
                  _buildButton(i, user, activeColor, inactiveColor),
              ],
            ),
          ),
        ),
        // Shadow only on top edge
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 4, // Shadow height
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                  blurRadius: 2.0,
                  offset: const Offset(0, -1),
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    int index,
    User? user,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _selectedIndex == index;
    final item = _items[index];

    // Profile item uses avatar instead of a plain icon
    final Widget? avatarChild = item.isProfile
        ? _AvatarIcon(
            photoUrl: user?.photoUrl,
            isSelected: isSelected,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          )
        : null;

    return _NavPillButton(
      icon: item.isProfile ? null : item.icon,
      child: avatarChild,
      isSelected: isSelected,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      semanticLabel: item.semanticLabel,
      onTap: () => _onItemTapped(index),
    );
  }
}

class _NavPillButton extends StatefulWidget {
  final IconData? icon; // icon OR child (avatar)
  final Widget? child;
  final String? semanticLabel;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavPillButton({
    this.icon,
    this.child,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  State<_NavPillButton> createState() => _NavPillButtonState();
}

class _NavPillButtonState extends State<_NavPillButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final showHighlight = widget.isSelected || _hovering;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: EdgeInsets.symmetric(
          horizontal: showHighlight ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: showHighlight
              ? widget.activeColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: widget.isSelected ? 1.08 : (_hovering ? 1.04 : 1.0),
            child: widget.child ??
                Icon(
                  widget.icon!,
                  size: widget.isSelected ? 28 : 24,
                  color: widget.isSelected
                      ? widget.activeColor
                      : widget.inactiveColor,
                  semanticLabel: widget.semanticLabel,
                ),
          ),
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final String? photoUrl;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _AvatarIcon({
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

class _NavItemData {
  final IconData icon;
  final String route;
  final String? semanticLabel;
  final bool isProfile;
  const _NavItemData({
    required this.icon,
    required this.route,
    this.semanticLabel,
    this.isProfile = false,
  });
}
