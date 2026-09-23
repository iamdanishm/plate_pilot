import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';
import 'package:plate_pilot/features/onboarding/data/household_repository.dart';
import 'package:plate_pilot/features/onboarding/domain/household_entity.dart';
import 'package:plate_pilot/features/pantry/domain/pantry_item_entity.dart';
import 'package:plate_pilot/features/pantry/presentation/controllers/pantry_controller.dart';
import 'package:plate_pilot/features/pantry/presentation/widgets/add_pantry_item_sheet.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddItemSheet(BuildContext context, String householdId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPantryItemSheet(householdId: householdId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final householdAsync = ref.watch(currentUserHouseholdProvider);

    return householdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            'Pantry & Fridge',
            style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Pantry & Fridge',
            style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Failed to load household pantry',
                  style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: AppTheme.fontStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(currentUserHouseholdProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (household) {
        if (household == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Pantry & Fridge',
                style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            body: Center(
              child: Text(
                'No active household found',
                style: AppTheme.fontStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }

        return _buildPantryContent(context, household, isIOS);
      },
    );
  }

  Widget _buildPantryContent(
    BuildContext context,
    HouseholdEntity household,
    bool isIOS,
  ) {
    final selectedFilter = ref.watch(pantryStorageFilterProvider);
    final counts = ref.watch(pantryCountsProvider(household.id));
    final filteredItemsAsync = ref.watch(filteredPantryListProvider(household.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pantry & Fridge',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('pantry_search_toggle_button'),
            icon: Icon(
              _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  ref.read(pantrySearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
        bottom: _isSearchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    key: const Key('pantry_search_field'),
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search items by name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(pantrySearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(pantrySearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(pantryControllerProvider(household.id).notifier)
              .loadItems();
        },
        child: Column(
          children: [
            // Filter Chips Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryFilterChip(
                    label: 'All',
                    count: counts['All'] ?? 0,
                    isSelected: selectedFilter == 'All',
                    onTap: () {
                      ref.read(pantryStorageFilterProvider.notifier).state = 'All';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip(
                    label: 'Fridge',
                    count: counts['Fridge'] ?? 0,
                    isSelected: selectedFilter == 'Fridge',
                    onTap: () {
                      ref.read(pantryStorageFilterProvider.notifier).state =
                          'Fridge';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip(
                    label: 'Pantry',
                    count: counts['Pantry'] ?? 0,
                    isSelected: selectedFilter == 'Pantry',
                    onTap: () {
                      ref.read(pantryStorageFilterProvider.notifier).state =
                          'Pantry';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip(
                    label: 'Freezer',
                    count: counts['Freezer'] ?? 0,
                    isSelected: selectedFilter == 'Freezer',
                    onTap: () {
                      ref.read(pantryStorageFilterProvider.notifier).state =
                          'Freezer';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryFilterChip(
                    label: 'Expiring Soon',
                    count: counts['Expiring Soon'] ?? 0,
                    isSelected: selectedFilter == 'Expiring Soon',
                    isUrgentChip: true,
                    onTap: () {
                      ref.read(pantryStorageFilterProvider.notifier).state =
                          'Expiring Soon';
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items List
            Expanded(
              child: filteredItemsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryEmerald,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading items: $err',
                          textAlign: TextAlign.center,
                          style: AppTheme.fontStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _buildEmptyState(context, household.id, selectedFilter);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];
                      return _buildDismissiblePantryItem(
                        context,
                        householdId: household.id,
                        item: item,
                        isIOS: isIOS,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_pantry_item_fab'),
        onPressed: () => _showAddItemSheet(context, household.id),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Item',
          style: AppTheme.fontStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool isUrgentChip = false,
  }) {
    final chipLabel = '$label ($count)';
    final activeColor = isUrgentChip
        ? AppTheme.accentTangerine
        : AppTheme.primaryEmerald;

    return FilterChip(
      key: Key('pantry_filter_${label.replaceAll(' ', '_').toLowerCase()}'),
      label: Text(
        chipLabel,
        style: AppTheme.fontStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      checkmarkColor: Colors.white,
      backgroundColor: isUrgentChip && count > 0 && !isSelected
          ? AppTheme.accentTangerine.withValues(alpha: 0.12)
          : null,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String householdId,
    String selectedFilter,
  ) {
    final isFiltered = selectedFilter != 'All' ||
        ref.read(pantrySearchQueryProvider).isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_alt_off_rounded
                    : Icons.kitchen_rounded,
                size: 40,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No items match your filter'
                  : 'Your pantry & fridge are empty',
              textAlign: TextAlign.center,
              style: AppTheme.fontStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try clearing your search query or selecting "All"'
                  : 'Track your ingredients, minimize waste, and enable AI meal planning by logging your pantry items.',
              textAlign: TextAlign.center,
              style: AppTheme.fontStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (isFiltered)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(pantrySearchQueryProvider.notifier).state = '';
                  ref.read(pantryStorageFilterProvider.notifier).state = 'All';
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showAddItemSheet(context, householdId),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissiblePantryItem(
    BuildContext context, {
    required String householdId,
    required PantryItemEntity item,
    required bool isIOS,
  }) {
    return Dismissible(
      key: Key('pantry_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: AppTheme.fontStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        ref
            .read(pantryControllerProvider(householdId).notifier)
            .deleteItem(item.id);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.name}"'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.secondaryAmber,
              onPressed: () {
                ref
                    .read(pantryControllerProvider(householdId).notifier)
                    .restoreItem(item);
              },
            ),
          ),
        );
      },
      child: _buildItemCard(context, householdId, item, isIOS),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    String householdId,
    PantryItemEntity item,
    bool isIOS,
  ) {
    final isUrgent = item.isExpiringSoon || item.isExpired;
    final location = item.storageLocation.toLowerCase();

    IconData locationIcon = Icons.inventory_2_outlined;
    if (location == 'fridge') {
      locationIcon = Icons.ac_unit_rounded;
    } else if (location == 'freezer') {
      locationIcon = Icons.severe_cold_rounded;
    }

    final cardContent = Row(
      children: [
        // Location Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUrgent
                ? AppTheme.accentTangerine.withValues(alpha: 0.12)
                : AppTheme.primaryEmerald.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            locationIcon,
            color: isUrgent ? AppTheme.accentTangerine : AppTheme.primaryEmerald,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),

        // Name and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTheme.fontStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.formattedQuantity.isNotEmpty ? "${item.formattedQuantity} • " : ""}${item.storageLocation.toUpperCase()}',
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Inline quantity adjuster (if numeric quantity exists)
        if (item.quantity != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () {
                    final currentQty = item.quantity!;
                    if (currentQty > 1) {
                      ref
                          .read(pantryControllerProvider(householdId).notifier)
                          .updateItemQuantity(item, currentQty - 1);
                    } else if (currentQty > 0.5) {
                      ref
                          .read(pantryControllerProvider(householdId).notifier)
                          .updateItemQuantity(item, currentQty - 0.5);
                    }
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {
                    final currentQty = item.quantity!;
                    ref
                        .read(pantryControllerProvider(householdId).notifier)
                        .updateItemQuantity(item, currentQty + 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Expiry Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: item.isExpired
                ? Colors.red.withValues(alpha: 0.12)
                : (item.isExpiringSoon
                    ? AppTheme.accentTangerine.withValues(alpha: 0.12)
                    : AppTheme.primaryEmerald.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.expirationBadgeText,
            style: AppTheme.fontStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.isExpired
                  ? Colors.red
                  : (item.isExpiringSoon
                      ? AppTheme.accentTangerine
                      : AppTheme.primaryEmerald),
            ),
          ),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: cardContent,
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: cardContent,
      ),
    );
  }
}
