import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/entry.dart';
import '../entries/entry_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_query.isEmpty
        ? recentEntriesProvider
        : entriesProvider(EntryFilter(searchQuery: _query)));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索标题、内容、标签、分类...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.neutral400),
          ),
          onChanged: (v) {
            setState(() => _query = v);
            ref.invalidate(entriesProvider);
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('全部', 'all'),
                _buildFilterChip('文本', 'text'),
                _buildFilterChip('密码', 'password'),
                _buildFilterChip('图片', 'image'),
                _buildFilterChip('文件', 'file'),
                _buildFilterChip('链接', 'link'),
              ],
            ),
          ),
          // Results
          Expanded(
            child: results.when(
              data: (entries) {
                final filtered = _selectedType == 'all'
                    ? entries
                    : entries.where((e) => e.type == _selectedType).toList();

                if (filtered.isEmpty && _query.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppColors.neutral300),
                        const SizedBox(height: 16),
                        Text('没有找到匹配的记录', style: TextStyle(color: AppColors.neutral500)),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: AppColors.neutral300),
                        const SizedBox(height: 16),
                        Text('输入关键词开始搜索', style: TextStyle(color: AppColors.neutral500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildResultCard(context, filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('搜索失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedType == type;
    final color = type == 'all' ? AppColors.primary : (AppColors.typeColors[type] ?? AppColors.neutral500);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedType = type),
        backgroundColor: Colors.transparent,
        selectedColor: color.withOpacity(0.15),
        labelStyle: TextStyle(
          color: isSelected ? color : AppColors.neutral600,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? color.withOpacity(0.3) : AppColors.neutral300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Entry entry) {
    final typeColor = AppColors.typeColors[entry.type] ?? AppColors.neutral500;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getTypeIcon(entry.type), color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.content ?? entry.url ?? entry.fileName ?? '',
                        style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.typeDisplayName,
                    style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'text': return Icons.text_snippet_outlined;
      case 'password': return Icons.lock_outline;
      case 'image': return Icons.image_outlined;
      case 'file': return Icons.insert_drive_file_outlined;
      case 'link': return Icons.link_outlined;
      default: return Icons.note_outlined;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
