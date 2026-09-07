import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pantry & Fridge',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Chips
            Row(
              children: [
                _buildCategoryChip('All (18)', true),
                const SizedBox(width: 8),
                _buildCategoryChip('Vegetables (6)', false),
                const SizedBox(width: 8),
                _buildCategoryChip('Dairy (4)', false),
                const SizedBox(width: 8),
                _buildCategoryChip('Grains (5)', false),
              ],
            ),
            const SizedBox(height: 20),

            _buildPantryItem(
              context,
              name: 'Paneer (Cottage Cheese)',
              quantity: '400 g',
              location: 'Fridge',
              daysLeft: 'Expires in 3 days',
              isUrgent: true,
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildPantryItem(
              context,
              name: 'Red Onions',
              quantity: '1.5 kg',
              location: 'Pantry',
              daysLeft: 'Stocked',
              isUrgent: false,
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildPantryItem(
              context,
              name: 'Basmati Rice',
              quantity: '2 kg',
              location: 'Pantry',
              daysLeft: 'Stocked',
              isUrgent: false,
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildPantryItem(
              context,
              name: 'Spinach (Palak)',
              quantity: '500 g',
              location: 'Fridge',
              daysLeft: 'Expires in 2 days',
              isUrgent: true,
              isIOS: isIOS,
            ),
            const SizedBox(height: 10),
            _buildPantryItem(
              context,
              name: 'Greek Yogurt / Curd',
              quantity: '400 g',
              location: 'Fridge',
              daysLeft: 'Expires in 5 days',
              isUrgent: false,
              isIOS: isIOS,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
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

  Widget _buildCategoryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: AppTheme.fontStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryEmerald,
      checkmarkColor: Colors.white,
      onSelected: (_) {},
    );
  }

  Widget _buildPantryItem(
    BuildContext context, {
    required String name,
    required String quantity,
    required String location,
    required String daysLeft,
    required bool isUrgent,
    required bool isIOS,
  }) {
    final content = Row(
      children: [
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
            location == 'Fridge'
                ? Icons.ac_unit_rounded
                : Icons.inventory_2_outlined,
            color:
                isUrgent ? AppTheme.accentTangerine : AppTheme.primaryEmerald,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTheme.fontStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$quantity • $location',
                style: AppTheme.fontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppTheme.accentTangerine.withValues(alpha: 0.12)
                : AppTheme.primaryEmerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            daysLeft,
            style: AppTheme.fontStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isUrgent ? AppTheme.accentTangerine : AppTheme.primaryEmerald,
            ),
          ),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: content,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: content,
      ),
    );
  }
}
