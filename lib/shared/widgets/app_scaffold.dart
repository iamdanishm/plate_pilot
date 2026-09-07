import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_container.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/onboarding/data/household_repository.dart';

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = AppTheme.isIOS;
    final household = ref.watch(currentUserHouseholdProvider).asData?.value;
    final groceryCount = household != null
        ? ref.watch(homeGroceryCountProvider(household.id)).asData?.value ?? 0
        : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isIOS
          ? _buildIOSGlassNavBar(context, groceryCount)
          : _buildMaterialNavBar(context, groceryCount),
    );
  }

  Widget _buildMaterialNavBar(BuildContext context, int groceryCount) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Plan',
        ),
        const NavigationDestination(
          icon: Icon(Icons.kitchen_outlined),
          selectedIcon: Icon(Icons.kitchen_rounded),
          label: 'Pantry',
        ),
        NavigationDestination(
          icon: groceryCount > 0
              ? Badge(
                  label: Text('$groceryCount'),
                  child: const Icon(Icons.shopping_basket_outlined),
                )
              : const Icon(Icons.shopping_basket_outlined),
          selectedIcon: groceryCount > 0
              ? Badge(
                  label: Text('$groceryCount'),
                  child: const Icon(Icons.shopping_basket_rounded),
                )
              : const Icon(Icons.shopping_basket_rounded),
          label: 'Grocery',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildIOSGlassNavBar(BuildContext context, int groceryCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassContainer(
          borderRadius: 28,
          blur: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIOSNavItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              _buildIOSNavItem(
                index: 1,
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_month_rounded,
                label: 'Plan',
                isDark: isDark,
              ),
              _buildIOSNavItem(
                index: 2,
                icon: Icons.kitchen_outlined,
                selectedIcon: Icons.kitchen_rounded,
                label: 'Pantry',
                isDark: isDark,
              ),
              _buildIOSNavItem(
                index: 3,
                icon: Icons.shopping_basket_outlined,
                selectedIcon: Icons.shopping_basket_rounded,
                label: 'Grocery',
                isDark: isDark,
                badgeCount: groceryCount,
              ),
              _buildIOSNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isDark,
    int badgeCount = 0,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected
        ? AppTheme.primaryEmerald
        : (isDark ? Colors.white60 : Colors.black54);

    Widget iconWidget = Icon(
      isSelected ? selectedIcon : icon,
      color: color,
      size: 24,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text('$badgeCount'),
        child: iconWidget,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _onDestinationSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.fontStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
