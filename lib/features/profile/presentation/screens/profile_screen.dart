import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';
import 'package:plate_pilot/features/auth/presentation/controllers/auth_controller.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out of PlatePilot?',
          style: AppTheme.fontStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  void _showFamilyMembersSheet(HouseholdEntity? household) {
    int adults = household?.adultsCount ?? 2;
    int children = household?.childrenCount ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Family Members',
                    style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust portion scaling across all planned meals.',
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildModalCounter(
                title: 'Adults (12+ yrs)',
                subtitle: 'Full portion calculations',
                value: adults,
                onIncrement: () => setSheetState(() => adults++),
                onDecrement: () => setSheetState(() {
                  if (adults > 1) adults--;
                }),
              ),
              const Divider(height: 24),
              _buildModalCounter(
                title: 'Children (Under 12)',
                subtitle: 'Adjusted portion calculations',
                value: children,
                onIncrement: () => setSheetState(() => children++),
                onDecrement: () => setSheetState(() {
                  if (children > 0) children--;
                }),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (household != null) {
                    await ref.read(householdRepositoryProvider).updateHouseholdMembers(
                          householdId: household.id,
                          adultsCount: adults,
                          childrenCount: children,
                          dietaryRestrictions: household.dietaryRestrictions,
                        );
                    ref.invalidate(currentUserHouseholdProvider);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated portions: $adults Adults, $children Children'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllergensSheet(HouseholdEntity? household) {
    final diets = household?.dietaryRestrictions ?? const [];
    final allergens = household?.allergens
            .map((a) {
              final val = a['allergen_id'] ?? a['custom_allergen'] ?? a['name'];
              return val?.toString().trim();
            })
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList() ??
        const [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allergens & Diets',
                  style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Strict exclusion rules applied to recipe candidate selection.',
              style: AppTheme.fontStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Active Dietary Profiles',
              style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: diets.isNotEmpty
                  ? diets.map((d) {
                      return Chip(
                        avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryEmerald),
                        label: Text(d.toString().replaceAll('_', ' ').toUpperCase()),
                        backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      );
                    }).toList()
                  : [
                      Chip(
                        avatar: const Icon(Icons.restaurant_rounded, size: 16, color: AppTheme.primaryEmerald),
                        label: const Text('STANDARD (NO RESTRICTIONS)'),
                        backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      ),
                    ],
            ),
            const SizedBox(height: 20),
            Text(
              'Strict Exclusions (Allergens)',
              style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergens.isNotEmpty
                  ? allergens.map((a) {
                      return Chip(
                        avatar: const Icon(Icons.shield_rounded, size: 16, color: Color(0xFFDC2626)),
                        label: Text(a.toUpperCase()),
                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      );
                    }).toList()
                  : [
                      Chip(
                        avatar: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.primaryEmerald),
                        label: const Text('NO ACTIVE ALLERGEN EXCLUSIONS'),
                        backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      ),
                    ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetSheet(HouseholdEntity? household) {
    double budget = household?.weeklyBudget ?? 3500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Grocery Budget',
                    style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'PlatePilot optimizes purchases to keep weekly meals within target.',
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '₹${budget.toInt()}',
                  style: AppTheme.fontStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
              ),
              Slider(
                value: budget,
                min: 1000,
                max: 10000,
                divisions: 18,
                label: '₹${budget.toInt()}',
                onChanged: (val) => setSheetState(() => budget = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (household != null) {
                    await ref.read(householdRepositoryProvider).updateWeeklyBudget(
                          householdId: household.id,
                          weeklyBudget: budget,
                        );
                    ref.invalidate(currentUserHouseholdProvider);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Weekly budget set to ₹${budget.toInt()}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCuisinesAndCookingTimesSheet(HouseholdEntity? household) {
    final cuisines = household?.preferredCuisines ?? [];
    final weekdayTime = household?.maxWeekdayCookingTimeMinutes ?? 45;
    final weekendTime = household?.maxWeekendCookingTimeMinutes ?? 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuisines & Cooking Times',
                  style: AppTheme.fontStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Preferences used for AI meal planning & recipe recommendations.',
              style: AppTheme.fontStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Preferred Cuisines',
              style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cuisines.isNotEmpty
                  ? cuisines.map((c) {
                      return Chip(
                        avatar: const Icon(Icons.restaurant_rounded, size: 16, color: AppTheme.primaryEmerald),
                        label: Text(c),
                        backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      );
                    }).toList()
                  : [
                      Chip(
                        avatar: const Icon(Icons.public_rounded, size: 16, color: AppTheme.primaryEmerald),
                        label: const Text('All Cuisines'),
                        backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      ),
                    ],
            ),
            const SizedBox(height: 20),
            Text(
              'Max Cooking Times',
              style: AppTheme.fontStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekday', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('$weekdayTime mins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekend', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('$weekendTime mins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppConstants.appName, style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appTagline, style: AppTheme.fontStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Text('Version: v${AppConstants.appVersion}', style: AppTheme.fontStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Architecture: Flutter • Supabase • Gemini', style: AppTheme.fontStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final householdAsync = ref.watch(currentUserHouseholdProvider);
    final household = householdAsync.asData?.value;
    final user = ref.watch(authControllerProvider).value;

    final householdName = household?.name.isNotEmpty == true ? household!.name : 'My Household';
    final adultsCount = household?.adultsCount ?? 2;
    final childrenCount = household?.childrenCount ?? 0;
    final budgetAmount = household?.weeklyBudget.toInt() ?? 3500;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Household Profile',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User & Household Card
            _buildProfileCard(
              context,
              isIOS: isIOS,
              householdName: householdName,
              userEmail: user?.email ?? 'user@platepilot.app',
              membersText: '$adultsCount Adults • $childrenCount Children',
            ),
            const SizedBox(height: 24),

            // Settings Group
            Text(
              'Household Settings',
              style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.family_restroom_rounded,
              title: 'Family Members',
              subtitle: '$adultsCount adults • $childrenCount children',
              onTap: () => _showFamilyMembersSheet(household),
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.no_food_rounded,
              title: 'Allergens & Exclusions',
              subtitle: 'Strict safety rules & diets',
              onTap: () => _showAllergensSheet(household),
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.payments_outlined,
              title: 'Weekly Budget Target',
              subtitle: '₹$budgetAmount / week',
              onTap: () => _showBudgetSheet(household),
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Cuisines & Cooking Times',
              subtitle: '${household?.preferredCuisines.isNotEmpty == true ? household!.preferredCuisines.join(', ') : 'All Cuisines'} • ${household?.maxWeekdayCookingTimeMinutes ?? 45}m weekdays',
              onTap: () => _showCuisinesAndCookingTimesSheet(household),
              isIOS: isIOS,
            ),
            const SizedBox(height: 24),

            Text(
              'Account & System',
              style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'About PlatePilot',
              subtitle: 'v${AppConstants.appVersion}',
              onTap: _showAboutDialog,
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildSettingTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Log out of this session',
              isDestructive: true,
              onTap: _handleSignOut,
              isIOS: isIOS,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required bool isIOS,
    required String householdName,
    required String userEmail,
    required String membersText,
  }) {
    final content = Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.15),
          child: Text(
            householdName.isNotEmpty ? householdName[0].toUpperCase() : 'H',
            style: AppTheme.fontStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryEmerald,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                householdName,
                style: AppTheme.fontStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userEmail,
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                membersText,
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.all(18),
        child: content,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: content,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isIOS,
    bool isDestructive = false,
  }) {
    final content = ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFDC2626) : AppTheme.primaryEmerald,
      ),
      title: Text(
        title,
        style: AppTheme.fontStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFDC2626) : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.fontStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );

    if (isIOS) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        child: content,
      );
    }
    return Card(
      child: content,
    );
  }

  Widget _buildModalCounter({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: AppTheme.fontStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Row(
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.remove_rounded, size: 20),
              onPressed: onDecrement,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filled(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}
