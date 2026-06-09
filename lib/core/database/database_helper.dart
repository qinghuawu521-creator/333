import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../models/entry.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/template.dart';
import '../models/password_entry.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        icon TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT,
        category_id TEXT,
        file_path TEXT,
        file_name TEXT,
        file_mime_type TEXT,
        file_size INTEGER,
        thumbnail_path TEXT,
        url TEXT,
        is_starred INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_encrypted INTEGER DEFAULT 0,
        custom_fields TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE entry_tags (
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (entry_id, tag_id),
        FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE password_entries (
        id TEXT PRIMARY KEY,
        platform TEXT NOT NULL,
        username TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        verification_info TEXT,
        notes TEXT,
        category_id TEXT,
        is_starred INTEGER DEFAULT 0,
        password_strength INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        entry_type TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        fields TEXT DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE password_tags (
        password_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (password_id, tag_id),
        FOREIGN KEY (password_id) REFERENCES password_entries(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_entries_category ON entries(category_id)');
    await db.execute('CREATE INDEX idx_entries_type ON entries(type)');
    await db.execute('CREATE INDEX idx_entries_starred ON entries(is_starred)');
    await db.execute('CREATE INDEX idx_entries_created ON entries(created_at)');
    await db.execute('CREATE INDEX idx_categories_parent ON categories(parent_id)');
    await db.execute('CREATE INDEX idx_passwords_platform ON password_entries(platform)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
  }

  // ==================== ENTRIES ====================

  Future<List<Entry>> getEntries({
    String? categoryId,
    String? type,
    bool? isStarred,
    String? searchQuery,
    String orderBy = 'updated_at DESC',
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (isStarred == true) {
      where.add('is_starred = 1');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(title LIKE ? OR content LIKE ? OR file_name LIKE ?)');
      final q = '%$searchQuery%';
      args.addAll([q, q, q]);
    }

    final results = await db.query(
      'entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    final entries = results.map((r) => Entry.fromMap(r)).toList();

    // Load tags for each entry
    for (var entry in entries) {
      entry.tagIds = await getEntryTagIds(entry.id);
    }

    return entries;
  }

  Future<Entry?> getEntry(String id) async {
    final db = await database;
    final results = await db.query('entries', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    final entry = Entry.fromMap(results.first);
    entry.tagIds = await getEntryTagIds(entry.id);
    return entry;
  }

  Future<void> insertEntry(Entry entry) async {
    final db = await database;
    await db.insert('entries', entry.toMap());
    await _updateEntryTags(entry.id, entry.tagIds);
  }

  Future<void> updateEntry(Entry entry) async {
    final db = await database;
    await db.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
    await _updateEntryTags(entry.id, entry.tagIds);
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleStar(String id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE entries SET is_starred = CASE WHEN is_starred = 1 THEN 0 ELSE 1 END,
      updated_at = ? WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  Future<void> togglePin(String id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE entries SET is_pinned = CASE WHEN is_pinned = 1 THEN 0 ELSE 1 END,
      updated_at = ? WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  Future<int> getEntryCount({String? categoryId}) async {
    final db = await database;
    if (categoryId != null) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM entries WHERE category_id = ?', [categoryId]);
      return result.first['count'] as int;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM entries');
    return result.first['count'] as int;
  }

  Future<Map<String, int>> getEntryCountByType() async {
    final db = await database;
    final results = await db.rawQuery('SELECT type, COUNT(*) as count FROM entries GROUP BY type');
    return {for (var r in results) r['type'] as String: r['count'] as int};
  }

  // ==================== CATEGORIES ====================

  Future<List<Category>> getCategories({String? parentId}) async {
    final db = await database;
    final results = await db.query(
      'categories',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map((r) => Category.fromMap(r)).toList();
  }

  Future<Category?> getCategory(String id) async {
    final db = await database;
    final results = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : Category.fromMap(results.first);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final results = await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return results.map((r) => Category.fromMap(r)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    // Move entries to uncategorized
    await db.update('entries', {'category_id': null}, where: 'category_id = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Category>> getCategoryPath(String categoryId) async {
    final path = <Category>[];
    var current = await getCategory(categoryId);
    while (current != null) {
      path.insert(0, current);
      if (current.parentId != null) {
        current = await getCategory(current.parentId!);
      } else {
        break;
      }
    }
    return path;
  }

  Future<int> getCategoryEntryCount(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM entries WHERE category_id = ?', [categoryId]);
    return result.first['count'] as int;
  }

  // ==================== TAGS ====================

  Future<List<Tag>> getTags() async {
    final db = await database;
    final results = await db.query('tags', orderBy: 'name ASC');
    return results.map((r) => Tag.fromMap(r)).toList();
  }

  Future<Tag?> getTag(String id) async {
    final db = await database;
    final results = await db.query('tags', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : Tag.fromMap(results.first);
  }

  Future<void> insertTag(Tag tag) async {
    final db = await database;
    await db.insert('tags', tag.toMap());
  }

  Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getEntryTagIds(String entryId) async {
    final db = await database;
    final results = await db.query('entry_tags', where: 'entry_id = ?', whereArgs: [entryId]);
    return results.map((r) => r['tag_id'] as String).toList();
  }

  Future<void> _updateEntryTags(String entryId, List<String> tagIds) async {
    final db = await database;
    await db.delete('entry_tags', where: 'entry_id = ?', whereArgs: [entryId]);
    for (final tagId in tagIds) {
      await db.insert('entry_tags', {'entry_id': entryId, 'tag_id': tagId});
    }
  }

  Future<List<Tag>> getTagsForEntry(String entryId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN entry_tags et ON t.id = et.tag_id
      WHERE et.entry_id = ?
      ORDER BY t.name ASC
    ''', [entryId]);
    return results.map((r) => Tag.fromMap(r)).toList();
  }

  // ==================== PASSWORDS ====================

  Future<List<PasswordEntry>> getPasswords({
    String? categoryId,
    bool? isStarred,
    String? searchQuery,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (isStarred == true) {
      where.add('is_starred = 1');
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(platform LIKE ? OR username LIKE ? OR email LIKE ? OR notes LIKE ?)');
      final q = '%$searchQuery%';
      args.addAll([q, q, q, q]);
    }

    final results = await db.query(
      'password_entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'platform ASC',
    );
    return results.map((r) => PasswordEntry.fromMap(r)).toList();
  }

  Future<PasswordEntry?> getPassword(String id) async {
    final db = await database;
    final results = await db.query('password_entries', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : PasswordEntry.fromMap(results.first);
  }

  Future<void> insertPassword(PasswordEntry entry) async {
    final db = await database;
    await db.insert('password_entries', entry.toMap());
  }

  Future<void> updatePassword(PasswordEntry entry) async {
    final db = await database;
    await db.update('password_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deletePassword(String id) async {
    final db = await database;
    await db.delete('password_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TEMPLATES ====================

  Future<List<Template>> getTemplates() async {
    final db = await database;
    final results = await db.query('templates', orderBy: 'name ASC');
    return results.map((r) => Template.fromMap(r)).toList();
  }

  Future<Template?> getTemplate(String id) async {
    final db = await database;
    final results = await db.query('templates', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : Template.fromMap(results.first);
  }

  Future<void> insertTemplate(Template template) async {
    final db = await database;
    await db.insert('templates', template.toMap());
  }

  Future<void> updateTemplate(Template template) async {
    final db = await database;
    await db.update('templates', template.toMap(), where: 'id = ?', whereArgs: [template.id]);
  }

  Future<void> deleteTemplate(String id) async {
    final db = await database;
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SEARCH ====================

  Future<List<Entry>> globalSearch(String query) async {
    final db = await database;
    final q = '%$query%';
    final results = await db.rawQuery('''
      SELECT DISTINCT e.* FROM entries e
      LEFT JOIN entry_tags et ON e.id = et.entry_id
      LEFT JOIN tags t ON et.tag_id = t.id
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.title LIKE ?
         OR e.content LIKE ?
         OR e.file_name LIKE ?
         OR e.url LIKE ?
         OR t.name LIKE ?
         OR c.name LIKE ?
      ORDER BY e.updated_at DESC
    ''', [q, q, q, q, q, q]);

    final entries = results.map((r) => Entry.fromMap(r)).toList();
    for (var entry in entries) {
      entry.tagIds = await getEntryTagIds(entry.id);
    }
    return entries;
  }

  Future<List<PasswordEntry>> searchPasswords(String query) async {
    final db = await database;
    final q = '%$query%';
    final results = await db.rawQuery('''
      SELECT DISTINCT p.* FROM password_entries p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.platform LIKE ?
         OR p.username LIKE ?
         OR p.email LIKE ?
         OR p.notes LIKE ?
         OR c.name LIKE ?
      ORDER BY p.platform ASC
    ''', [q, q, q, q, q]);
    return results.map((r) => PasswordEntry.fromMap(r)).toList();
  }

  // ==================== BACKUP ====================

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final entries = await db.query('entries');
    final categories = await db.query('categories');
    final tags = await db.query('tags');
    final entryTags = await db.query('entry_tags');
    final passwords = await db.query('password_entries');
    final templates = await db.query('templates');

    return {
      'version': AppConstants.dbVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'entries': entries,
      'categories': categories,
      'tags': tags,
      'entry_tags': entryTags,
      'password_entries': passwords,
      'templates': templates,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('entry_tags');
      await txn.delete('entries');
      await txn.delete('password_entries');
      await txn.delete('templates');
      await txn.delete('tags');
      await txn.delete('categories');

      // Import categories
      for (final cat in (data['categories'] as List)) {
        await txn.insert('categories', Map<String, dynamic>.from(cat));
      }
      // Import tags
      for (final tag in (data['tags'] as List)) {
        await txn.insert('tags', Map<String, dynamic>.from(tag));
      }
      // Import entries
      for (final entry in (data['entries'] as List)) {
        await txn.insert('entries', Map<String, dynamic>.from(entry));
      }
      // Import entry_tags
      for (final et in (data['entry_tags'] as List)) {
        await txn.insert('entry_tags', Map<String, dynamic>.from(et));
      }
      // Import passwords
      for (final pwd in (data['password_entries'] as List)) {
        await txn.insert('password_entries', Map<String, dynamic>.from(pwd));
      }
      // Import templates
      for (final tpl in (data['templates'] as List)) {
        await txn.insert('templates', Map<String, dynamic>.from(tpl));
      }
    });
  }
}
