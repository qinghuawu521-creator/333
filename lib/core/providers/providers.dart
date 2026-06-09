import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/entry.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/template.dart';
import '../models/password_entry.dart';

// ==================== DATABASE PROVIDER ====================

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// ==================== THEME PROVIDER ====================

enum ThemeModeOption { system, light, dark }

final themeModeProvider = StateProvider<ThemeModeOption>((ref) => ThemeModeOption.system);

// ==================== ENTRIES ====================

final entriesProvider = FutureProvider.family<List<Entry>, EntryFilter>((ref, filter) async {
  final db = ref.read(databaseProvider);
  return await db.getEntries(
    categoryId: filter.categoryId,
    type: filter.type,
    isStarred: filter.isStarred,
    searchQuery: filter.searchQuery,
    orderBy: filter.orderBy,
    limit: filter.limit,
    offset: filter.offset,
  );
});

final starredEntriesProvider = FutureProvider<List<Entry>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getEntries(isStarred: true, orderBy: 'updated_at DESC');
});

final recentEntriesProvider = FutureProvider<List<Entry>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getEntries(orderBy: 'updated_at DESC', limit: 20);
});

final entryProvider = FutureProvider.family<Entry?, String>((ref, id) async {
  final db = ref.read(databaseProvider);
  return await db.getEntry(id);
});

final entryCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getEntryCountByType();
});

final totalEntryCountProvider = FutureProvider<int>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getEntryCount();
});

class EntryFilter {
  final String? categoryId;
  final String? type;
  final bool? isStarred;
  final String? searchQuery;
  final String orderBy;
  final int? limit;
  final int? offset;

  const EntryFilter({
    this.categoryId,
    this.type,
    this.isStarred,
    this.searchQuery,
    this.orderBy = 'updated_at DESC',
    this.limit,
    this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryFilter &&
          categoryId == other.categoryId &&
          type == other.type &&
          isStarred == other.isStarred &&
          searchQuery == other.searchQuery &&
          orderBy == other.orderBy &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(categoryId, type, isStarred, searchQuery, orderBy, limit, offset);
}

// ==================== CATEGORIES ====================

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllCategories();
});

final rootCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getCategories(parentId: null);
});

final subCategoriesProvider = FutureProvider.family<List<Category>, String>((ref, parentId) async {
  final db = ref.read(databaseProvider);
  return await db.getCategories(parentId: parentId);
});

final categoryProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final db = ref.read(databaseProvider);
  return await db.getCategory(id);
});

final categoryPathProvider = FutureProvider.family<List<Category>, String>((ref, id) async {
  final db = ref.read(databaseProvider);
  return await db.getCategoryPath(id);
});

// ==================== TAGS ====================

final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTags();
});

final entryTagsProvider = FutureProvider.family<List<Tag>, String>((ref, entryId) async {
  final db = ref.read(databaseProvider);
  return await db.getTagsForEntry(entryId);
});

// ==================== PASSWORDS ====================

final passwordsProvider = FutureProvider<List<PasswordEntry>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getPasswords();
});

final starredPasswordsProvider = FutureProvider<List<PasswordEntry>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getPasswords(isStarred: true);
});

final passwordProvider = FutureProvider.family<PasswordEntry?, String>((ref, id) async {
  final db = ref.read(databaseProvider);
  return await db.getPassword(id);
});

// ==================== TEMPLATES ====================

final templatesProvider = FutureProvider<List<Template>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTemplates();
});

final templateProvider = FutureProvider.family<Template?, String>((ref, id) async {
  final db = ref.read(databaseProvider);
  return await db.getTemplate(id);
});

// ==================== SEARCH ====================

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Entry>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final db = ref.read(databaseProvider);
  return await db.globalSearch(query);
});

final passwordSearchResultsProvider = FutureProvider<List<PasswordEntry>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final db = ref.read(databaseProvider);
  return await db.searchPasswords(query);
});

// ==================== REFRESH HELPERS ====================

final refreshProvider = StateProvider<int>((ref) => 0);

void refreshAll(WidgetRef ref) {
  ref.invalidate(entriesProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(rootCategoriesProvider);
  ref.invalidate(tagsProvider);
  ref.invalidate(passwordsProvider);
  ref.invalidate(templatesProvider);
  ref.invalidate(starredEntriesProvider);
  ref.invalidate(recentEntriesProvider);
  ref.invalidate(entryCountProvider);
  ref.invalidate(totalEntryCountProvider);
  ref.read(refreshProvider.notifier).state++;
}

void refreshEntries(WidgetRef ref) {
  ref.invalidate(entriesProvider);
  ref.invalidate(starredEntriesProvider);
  ref.invalidate(recentEntriesProvider);
  ref.invalidate(entryCountProvider);
  ref.invalidate(totalEntryCountProvider);
  ref.read(refreshProvider.notifier).state++;
}

void refreshCategories(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  ref.invalidate(rootCategoriesProvider);
  ref.read(refreshProvider.notifier).state++;
}

void refreshPasswords(WidgetRef ref) {
  ref.invalidate(passwordsProvider);
  ref.invalidate(starredPasswordsProvider);
  ref.read(refreshProvider.notifier).state++;
}
