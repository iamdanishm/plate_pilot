import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = AppTheme.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Meal Plan',
          style: AppTheme.fontStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.primaryEmerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Week of Sept 1 – Sept 7 • 7 Meals Planned',
                      style: AppTheme.fontStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plan List by Days
            _buildDayCard(
              context,
              day: 'Monday',
              meal: 'Palak Paneer with Garlic Naan',
              tag: 'Pantry Match (85%) • 35m',
              isIOS: isIOS,
            ),
            const SizedBox(height: 12),
            _buildDayCard(
              context,
              day: 'Tuesday',
              meal: 'Rajma Chawal with Kachumber Salad',
              tag: 'High Protein • 40m',
              isIOS: isIOS,
            ),
            const SizedBox(height: 12),
            _buildDayCard(
              context,
              day: 'Wednesday',
              meal: 'Vegetable Biryani with Cucumber Raita',
              tag: 'Vegetarian • 45m',
              isIOS: isIOS,
            ),
            const SizedBox(height: 12),
            _buildDayCard(
              context,
              day: 'Thursday',
              meal: 'Aloo Gobi with Whole Wheat Chapati',
              tag: 'Budget Saver • 25m',
              isIOS: isIOS,
            ),
            const SizedBox(height: 12),
            _buildDayCard(
              context,
              day: 'Friday',
              meal: 'Dal Makhani with Jeera Rice',
              tag: 'Weekend Special • 45m',
              isIOS: isIOS,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(
          'Regenerate Plan',
          style: AppTheme.fontStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context, {
    required String day,
    required String meal,
    required String tag,
    required bool isIOS,
  }) {
    final content = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              day.substring(0, 3).toUpperCase(),
              style: AppTheme.fontStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal,
                style: AppTheme.fontStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tag,
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Swap Meal',
          onPressed: () {},
        ),
      ],
    );

    if (isIOS) {
      return GlassContainer(
        padding: const EdgeInsets.all(14),
        child: content,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: content,
      ),
    );
  }
}
