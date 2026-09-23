import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/features/pantry/data/pantry_repository.dart';
import 'package:plate_pilot/features/pantry/domain/canonical_ingredient_entity.dart';
import 'package:plate_pilot/features/pantry/presentation/controllers/pantry_controller.dart';

class AddPantryItemSheet extends ConsumerStatefulWidget {
  final String householdId;

  const AddPantryItemSheet({
    super.key,
    required this.householdId,
  });

  @override
  ConsumerState<AddPantryItemSheet> createState() => _AddPantryItemSheetState();
}

class _AddPantryItemSheetState extends ConsumerState<AddPantryItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _amountDescController = TextEditingController();

  CanonicalIngredientEntity? _selectedCanonical;
  List<CanonicalIngredientEntity> _suggestions = [];
  bool _isSearching = false;

  String _storageLocation = 'pantry';
  String _selectedUnit = 'pcs';
  DateTime? _expiresAt;
  bool _isQualitative = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _units = [
    'pcs',
    'g',
    'kg',
    'ml',
    'l',
    'cup',
    'tbsp',
    'tsp',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _amountDescController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(pantryRepositoryProvider);
      final results = await repo.searchCanonicalIngredients(trimmed, limit: 6);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectCanonical(CanonicalIngredientEntity canonical) {
    setState(() {
      _selectedCanonical = canonical;
      _nameController.text = canonical.name;
      _storageLocation = canonical.defaultStorage;
      if (_units.contains(canonical.defaultUnit.toLowerCase())) {
        _selectedUnit = canonical.defaultUnit.toLowerCase();
      }
      _expiresAt = canonical.calculatedDefaultExpiration;
      _suggestions = [];
    });
  }

  void _applyQuickExpiry(int days) {
    final now = DateTime.now();
    setState(() {
      _expiresAt = DateTime(now.year, now.month, now.day + days);
    });
  }

  Future<void> _pickCustomExpiryDate() async {
    final now = DateTime.now();
    final initialDate = _expiresAt ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryEmerald,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      double? qty;
      String? unit;
      String? amountDesc;

      if (_isQualitative) {
        amountDesc = _amountDescController.text.trim();
        if (amountDesc.isEmpty) {
          amountDesc = 'As needed';
        }
      } else {
        qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
        unit = _selectedUnit;
      }

      await ref
          .read(pantryControllerProvider(widget.householdId).notifier)
          .addItem(
            name: name,
            canonicalIngredientId: _selectedCanonical?.id,
            quantity: qty,
            unit: unit,
            amountDescription: amountDesc,
            storageLocation: _storageLocation,
            expiresAt: _expiresAt,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$name" to $_storageLocation'),
            backgroundColor: AppTheme.primaryEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.neutralSurfaceDark
              : AppTheme.neutralSurfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Pantry Item',
                      style: AppTheme.fontStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.fontStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // Item Name with live autocomplete
                TextFormField(
                  key: const Key('add_pantry_item_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Paneer, Basmati Rice, Onion',
                    prefixIcon: const Icon(Icons.restaurant_menu_rounded),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_selectedCanonical != null
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryEmerald,
                              )
                            : null),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (val) {
                    if (_selectedCanonical != null &&
                        val != _selectedCanonical!.name) {
                      setState(() => _selectedCanonical = null);
                    }
                    _onSearchChanged(val);
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),

                // Canonical Suggestions
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: isDark
                        ? AppTheme.neutralSurfaceVariantDark
                        : AppTheme.neutralSurfaceVariantLight,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                        final item = _suggestions[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.name,
                            style: AppTheme.fontStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${item.category} • Default: ${item.defaultStorage} (${item.shelfLifeDays}d shelf life)',
                            style: AppTheme.fontStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                          ),
                          onTap: () => _selectCanonical(item),
                        );
                      },
                    ),
                  ),
                ),
              ],
                const SizedBox(height: 16),

                // Storage Location Selector
                Text(
                  'Storage Location',
                  style: AppTheme.fontStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStorageChip(
                        label: 'Pantry',
                        location: 'pantry',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStorageChip(
                        label: 'Fridge',
                        location: 'fridge',
                        icon: Icons.ac_unit_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStorageChip(
                        label: 'Freezer',
                        location: 'freezer',
                        icon: Icons.severe_cold_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quantity & Unit or Qualitative
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isQualitative ? 'Amount Description' : 'Quantity & Unit',
                      style: AppTheme.fontStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isQualitative = !_isQualitative);
                      },
                      child: Text(
                        _isQualitative
                            ? 'Switch to numeric'
                            : 'Rough amount (e.g. half bottle)',
                        style: AppTheme.fontStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (_isQualitative) ...[
                  TextFormField(
                    controller: _amountDescController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 1 bunch, half jar, a few pieces',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: const Key('add_pantry_item_quantity_field'),
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: const Icon(Icons.scale_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (val) {
                            if (!_isQualitative && (val == null || val.trim().isEmpty)) {
                              return 'Enter qty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: _units.map((u) {
                            return DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedUnit = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Expiration Date
                Text(
                  'Expiration Date (Optional)',
                  style: AppTheme.fontStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickCustomExpiryDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppTheme.primaryEmerald,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _expiresAt != null
                                ? 'Expires: ${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}'
                                : 'No expiration date selected',
                            style: AppTheme.fontStyle(
                              fontSize: 14,
                              fontWeight: _expiresAt != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_expiresAt != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _expiresAt = null),
                          )
                        else
                          const Icon(Icons.edit_calendar_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Expiry Presets
                Wrap(
                  spacing: 6,
                  children: [
                    _buildExpiryPresetChip('+3 days', 3),
                    _buildExpiryPresetChip('+1 week', 7),
                    _buildExpiryPresetChip('+2 weeks', 14),
                    _buildExpiryPresetChip('+1 month', 30),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  key: const Key('add_pantry_item_submit_button'),
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save to Pantry',
                          style: AppTheme.fontStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageChip({
    required String label,
    required String location,
    required IconData icon,
  }) {
    final isSelected = _storageLocation == location;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppTheme.primaryEmerald,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryEmerald,
      labelStyle: AppTheme.fontStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      onSelected: (_) {
        setState(() => _storageLocation = location);
      },
    );
  }

  Widget _buildExpiryPresetChip(String label, int days) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: AppTheme.fontStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => _applyQuickExpiry(days),
    );
  }
}
