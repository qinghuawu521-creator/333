import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/category.dart';
import '../../core/database/database_helper.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String? _selectedCategoryId;
  final List<String> _navigationStack = [];

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
      _selectedCategoryId == null
          ? rootCategoriesProvider
          : subCategoriesProvider(_selectedCategoryId!),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategoryId == null ? '分类' : '子分类'),
        leading: _selectedCategoryId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: categories.when(
        data: (cats) => cats.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cats.length,
                itemBuilder: (context, index) => _buildCategoryTile(context, cats[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    final color = category.color != null
        ? AppColors.hexToColor(category.color!)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(category.icon),
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: FutureBuilder<int>(
            future: DatabaseHelper.instance.getCategoryEntryCount(category.id),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Text(
                '$count 条记录',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              );
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.neutral500),
                onPressed: () => _showEditCategoryDialog(context, category),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                onPressed: () => _confirmDelete(context, category),
              ),
              const Icon(Icons.chevron_right, color: AppColors.neutral400),
            ],
          ),
          onTap: () {
            setState(() {
              _navigationStack.add(_selectedCategoryId ?? '');
              _selectedCategoryId = category.id;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text(
            '还没有分类',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 创建分类',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.neutral400),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        final prev = _navigationStack.removeLast();
        _selectedCategoryId = prev.isEmpty ? null : prev;
      });
    } else {
      setState(() => _selectedCategoryId = null);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.categoryColors[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  hintText: '输入分类名称',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.categoryColors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final category = Category(
                  name: nameController.text.trim(),
                  parentId: _selectedCategoryId,
                  color: AppColors.colorToHex(selectedColor),
                );
                await DatabaseHelper.instance.insertCategory(category);
                if (mounted) {
                  Navigator.pop(context);
                  refreshCategories(ref);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    Color selectedColor = category.color != null
        ? AppColors.hexToColor(category.color!)
        : AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.categoryColors.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final updated = category.copyWith(
                  name: nameController.text.trim(),
                  color: AppColors.colorToHex(selectedColor),
                );
                await DatabaseHelper.instance.updateCategory(updated);
                if (mounted) {
                  Navigator.pop(context);
                  refreshCategories(ref);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定要删除「${category.name}」吗？该分类下的记录将变为未分类。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(category.id);
              if (mounted) {
                Navigator.pop(context);
                refreshCategories(ref);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    if (icon == null) return Icons.folder_outlined;
    final iconMap = {
      'work': Icons.work_outline,
      'life': Icons.home_outlined,
      'study': Icons.school_outlined,
      'finance': Icons.account_balance_wallet_outlined,
      'health': Icons.favorite_outline,
      'travel': Icons.flight_outlined,
      'photo': Icons.photo_outlined,
      'code': Icons.code_outlined,
      'music': Icons.music_note_outlined,
      'book': Icons.menu_book_outlined,
    };
    return iconMap[icon] ?? Icons.folder_outlined;
  }
}
