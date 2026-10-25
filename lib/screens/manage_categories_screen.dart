import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/animated_action_dialog.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _isDeleting = false;

  void _openCreateCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateCategorySheet(),
    );
  }

  Future<void> _confirmDeleteCategory(CategoryModel category) async {
    if (_isDeleting) return;

    final confirmed = await ActionConfirmationDialog.show(
      context,
      title: 'Delete Category?',
      message: 'Are you sure you want to delete "${category.name}"? Only custom categories can be deleted.',
      confirmText: 'Delete Category',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final provider = context.read<ExpenseProvider>();
      final success = await provider.deleteCategory(category.id);

      if (mounted) {
        if (success) {
          await AnimatedSuccessDialog.show(
            context,
            title: 'Category Deleted',
            subtitle: '"${category.name}" was removed',
            icon: Icons.delete_sweep_rounded,
            accentColor: const Color(0xFFEF4444),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete category'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted && _isDeleting) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final allCategories = provider.categories;
    final customCategories = allCategories.where((c) => !c.isDefault).toList();
    final defaultCategories = allCategories.where((c) => c.isDefault).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.pureBlack,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.category_rounded,
                        size: 24,
                        color: isDark ? Colors.white : AppTheme.pureBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${allCategories.length} Total Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${customCategories.length} custom • ${defaultCategories.length} default (protected)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grayTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Section 1: Custom Categories
            Row(
              children: [
                const Text(
                  'custom categories',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grayTextMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE4E4E7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${customCategories.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                ),
                const Spacer(),
                // Add action on the edge right inline the custom categories text
                InkWell(
                  onTap: () => _openCreateCategorySheet(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: isDark ? AppTheme.pureBlack : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.pureBlack : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (customCategories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141416)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : AppTheme.grayBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 32,
                      color: isDark ? Colors.white38 : AppTheme.grayTextMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No custom categories yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppTheme.pureBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create custom categories tailored to your expenses.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grayTextMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _openCreateCategorySheet(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white
                            : AppTheme.pureBlack,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF3F3F46)
                              : AppTheme.grayBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Custom Category'),
                    ),
                  ],
                ),
              )
            else
              ...customCategories.map((category) {
                return _buildCategoryTile(
                  context: context,
                  category: category,
                  isDark: isDark,
                  isCustom: true,
                  onDelete: () => _confirmDeleteCategory(category),
                );
              }),

            const SizedBox(height: 32),

            // Section 2: Default Categories
            Row(
              children: [
                const Text(
                  'default categories',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grayTextMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFE4E4E7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${defaultCategories.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...defaultCategories.map((category) {
              return _buildCategoryTile(
                context: context,
                category: category,
                isDark: isDark,
                isCustom: false,
                onDelete: null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required CategoryModel category,
    required bool isDark,
    required bool isCustom,
    required VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
        ),
      ),
      child: Row(
        children: [
          // Category icon container with vibrant color accent
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: isDark ? 0.20 : 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(category.icon, size: 20, color: category.color),
            ),
          ),
          const SizedBox(width: 14),

          // Name (no emoji)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white : AppTheme.pureBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isCustom ? 'Custom category' : 'System default',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.grayTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Badge / Delete Action
          if (isCustom) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: category.color.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Text(
                'Custom',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: category.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Color(0xFFEF4444),
              ),
              tooltip: 'Delete custom category',
              onPressed: _isDeleting ? null : onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 11,
                    color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : AppTheme.grayTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet();

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  final _nameController = TextEditingController();
  String _selectedIconKey = 'category';
  String _selectedColorHex = CategoryModel.curatedColors.first;
  bool _isSubmitting = false;
  String? _errorMessage;

  Color get _selectedColor {
    try {
      final hex = _selectedColorHex.replaceAll('#', '').trim();
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a category name');
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final exists = provider.categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      setState(
        () => _errorMessage = 'A category with this name already exists',
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final created = await provider.addCategory(
      name: name,
      emoji: '',
      iconName: _selectedIconKey,
      colorHex: _selectedColorHex,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (created != null) {
        Navigator.pop(context);
        final color = Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF')));
        await AnimatedSuccessDialog.show(
          context,
          title: 'Category Created!',
          subtitle: '"${created.name}" is now ready to use',
          icon: CategoryModel.getIconByName(_selectedIconKey) ?? Icons.check_circle_rounded,
          accentColor: color,
        );
      } else {
        setState(() => _errorMessage = 'Failed to create category');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedIconData =
        CategoryModel.getIconByName(_selectedIconKey) ??
        Icons.inventory_2_rounded;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Custom Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.pureBlack,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Preview Card (Clean, Monochromatic, No Emoji)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E22)
                          : AppTheme.grayKeypad,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : AppTheme.grayBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedColor.withValues(
                              alpha: isDark ? 0.20 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              selectedIconData,
                              size: 24,
                              color: _selectedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.trim().isEmpty
                                    ? 'Category Name'
                                    : _nameController.text.trim(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.pureBlack,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Live Preview (Custom Category)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.grayTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedColor.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedColor.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Name Input
                  Text(
                    'Category Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Gaming, Subscriptions, Fitness...',
                      hintStyle: const TextStyle(color: AppTheme.grayTextMuted),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E22)
                          : AppTheme.grayKeypad,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : AppTheme.grayBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : AppTheme.grayBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (_errorMessage != null) _errorMessage = null;
                      });
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Color Accent Palette Picker
                  Text(
                    'Color Accent',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: CategoryModel.curatedColors.map((hex) {
                      final isSelected =
                          _selectedColorHex.toLowerCase() == hex.toLowerCase();
                      final color = Color(
                        int.parse('0xFF${hex.replaceAll('#', '')}'),
                      );
                      return InkWell(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: isSelected ? 2.5 : 0,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Vector Icon Picker
                  Text(
                    'Select Vector Icon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: CategoryModel.iconChoices.map((opt) {
                      final isSelected = _selectedIconKey == opt.key;
                      return InkWell(
                        onTap: () => setState(() => _selectedIconKey = opt.key),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : AppTheme.pureBlack)
                                : (isDark
                                      ? const Color(0xFF1E1E22)
                                      : AppTheme.grayKeypad),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : AppTheme.pureBlack)
                                  : (isDark
                                        ? const Color(0xFF27272A)
                                        : AppTheme.grayBorder),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt.icon,
                                size: 18,
                                color: isSelected
                                    ? (isDark
                                          ? AppTheme.pureBlack
                                          : Colors.white)
                                    : (isDark
                                          ? Colors.white70
                                          : AppTheme.pureBlack),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark
                                            ? AppTheme.pureBlack
                                            : Colors.white)
                                      : (isDark
                                            ? Colors.white70
                                            : AppTheme.pureBlack),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white
                            : AppTheme.pureBlack,
                        foregroundColor: isDark
                            ? AppTheme.pureBlack
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Create Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
