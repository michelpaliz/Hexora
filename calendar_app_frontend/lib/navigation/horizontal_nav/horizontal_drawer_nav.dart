import 'package:flutter/material.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/navigation/horizontal_nav/components/avatar_icon.dart';
import 'package:hexora/navigation/horizontal_nav/models/nav_item_data.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HorizontalDrawerNav extends StatefulWidget {
  const HorizontalDrawerNav({super.key});

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
    AppRoutes.homePage: 0,
    AppRoutes.showGroups: 0,
    AppRoutes.agenda: 0,
    AppRoutes.groupDashboard: 0,
    AppRoutes.showNotifications: 1,
    AppRoutes.profileDetails: 2,
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
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final user = context.watch<UserDomain>().user;
    final labels = [l.home, l.notifications, l.profile];

    return NavigationBar(
      height: 80,
      elevation: 0,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: cs.secondaryContainer,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? cs.onSurface
                : cs.onSurfaceVariant,
          )),
      destinations: [
        for (var i = 0; i < _items.length; i++)
          NavigationDestination(
            label: labels[i],
            tooltip: labels[i],
            icon: _items[i].isProfile
                ? AvatarIcon(
                    photoUrl: user?.photoUrl,
                    isSelected: _selectedIndex == i,
                    activeColor: cs.onSecondaryContainer,
                    inactiveColor: cs.onSurfaceVariant,
                  )
                : Icon(_items[i].icon, size: 24),
          ),
      ],
    );
  }
}
