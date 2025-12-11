import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/horizontal_drawer_nav/components/avatar_icon.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/horizontal_drawer_nav/components/nav_pill_button.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/horizontal_drawer_nav/models/nav_item_data.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HorizontalDrawerNav extends StatefulWidget {
  const HorizontalDrawerNav({
    super.key,
    this.centerGapWidth = 80,
  });

  final double centerGapWidth;

  @override
  State<HorizontalDrawerNav> createState() => _HorizontalDrawerNavState();
}

class _HorizontalDrawerNavState extends State<HorizontalDrawerNav> {
  int _selectedIndex = 0;

  final List<NavItemData> _items = const [
    NavItemData(
      icon: Iconsax.home_1,
      route: AppRoutes.homePage,
      semanticLabel: 'Home',
    ),
    NavItemData(
      icon: Iconsax.calendar_1,
      route: AppRoutes.agenda,
      semanticLabel: 'Agenda',
    ),
    NavItemData(
      icon: Iconsax.notification,
      route: AppRoutes.showNotifications,
      semanticLabel: 'Notifications',
    ),
    NavItemData(
      icon: Iconsax.user,
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

    // ✅ no manual bottom padding here; Scaffold/BottomAppBar handle system insets
    return Stack(
      children: [
        Container(
          height: 56, // fixed bar height
          width: double.infinity,
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
          child: IgnorePointer(
            // just in case, so it doesn't eat taps
            child: Container(
              height: 4,
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

    final Widget? avatarChild = item.isProfile
        ? AvatarIcon(
            photoUrl: user?.photoUrl,
            isSelected: isSelected,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
          )
        : null;

    return NavPillButton(
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
