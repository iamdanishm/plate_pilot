import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final Map<String, bool> _checkedItems = {
    'Fresh Tomatoes (1 kg)': false,
    'Ginger & Garlic (200 g)': false,
    'Garam Masala (100 g)': false,
    'Mustard Oil (1 L)': true,
    'Whole Wheat Atta (5 kg)': false,
  };

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;
    final checkedCount = _checkedItems.values.where((v) => v).length;
    final totalCount = _checkedItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Grocery List',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aggregation Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.secondaryAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.secondaryAmber.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    color: AppTheme.secondaryAmberDark,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aggregated from 7 planned meals',
                          style: AppTheme.fontStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryAmberDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$checkedCount of $totalCount items purchased • Est. ${AppConstants.defaultCurrencySymbol}850',
                          style: AppTheme.fontStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Required Purchases',
              style: AppTheme.fontStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            ..._checkedItems.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildGroceryItem(
                  title: entry.key,
                  isChecked: entry.value,
                  isIOS: isIOS,
                  onChanged: (val) {
                    setState(() {
                      _checkedItems[entry.key] = val ?? false;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryItem({
    required String title,
    required bool isChecked,
    required bool isIOS,
    required ValueChanged<bool?> onChanged,
  }) {
    final content = Row(
      children: [
        Checkbox(
          value: isChecked,
          activeColor: AppTheme.primaryEmerald,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTheme.fontStyle(
              fontSize: 15,
              fontWeight: isChecked ? FontWeight.w400 : FontWeight.w600,
            ).copyWith(
              decoration:
                  isChecked ? TextDecoration.lineThrough : TextDecoration.none,
              color: isChecked ? Colors.grey : null,
            ),
          ),
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: content,
      ),
    );
  }
}
