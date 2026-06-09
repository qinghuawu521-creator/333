import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/models/entry.dart';
import '../search/search_screen.dart';
import '../entries/entry_editor_screen.dart';
import '../entries/entry_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryCounts = ref.watch(entryCountProvider);
    final recentEntries = ref.watch(recentEntriesProvider);
    final starredEntries = ref.watch(starredEntriesProvider);
    final totalCount = ref.watch(totalEntryCountProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Vault',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              totalCount.when(
                                data: (count) => Text(
                                  '共 $count 条记录',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                loading: () => const SizedBox(),
                                error: (_, __) => const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          ),
                          icon: const Icon(Icons.search),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.neutral100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search bar
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: AppColors.neutral400, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '搜索所有记录...',
                              style: TextStyle(color: AppColors.neutral400, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: entryCounts.when(
                  data: (counts) => _buildStatsGrid(context, counts),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // Starred section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '收藏',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            starredEntries.when(
              data: (entries) => entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyState(context, '还没有收藏记录', Icons.star_border_rounded),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildEntryCard(context, ref, entries[index]),
                        childCount: entries.length > 5 ? 5 : entries.length,
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            // Recent section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppColors.info, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '最近',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            recentEntries.when(
              data: (entries) => entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyState(context, '还没有记录，点击 + 开始添加', Icons.note_add_outlined),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildEntryCard(context, ref, entries[index]),
                        childCount: entries.length,
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('新建'),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> counts) {
    final items = [
      _StatItem('文本', Icons.text_snippet_outlined, AppColors.typeColors['text']!, counts['text'] ?? 0),
      _StatItem('密码', Icons.lock_outline, AppColors.typeColors['password']!, counts['password'] ?? 0),
      _StatItem('图片', Icons.image_outlined, AppColors.typeColors['image']!, counts['image'] ?? 0),
      _StatItem('文件', Icons.insert_drive_file_outlined, AppColors.typeColors['file']!, counts['file'] ?? 0),
      _StatItem('链接', Icons.link_outlined, AppColors.typeColors['link']!, counts['link'] ?? 0),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 22),
              const SizedBox(height: 4),
              Text(
                '${item.count}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, WidgetRef ref, Entry entry) {
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
                // Type indicator
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
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.isStarred)
                            Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                          if (entry.isPinned)
                            Icon(Icons.push_pin, color: AppColors.primary, size: 14),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.content ?? entry.url ?? entry.fileName ?? entry.typeDisplayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppDateUtils.formatRelative(entry.updatedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.neutral300),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  '新建记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              _buildAddOption(context, '文本记录', Icons.text_snippet_outlined, AppColors.typeColors['text']!, 'text'),
              _buildAddOption(context, '密码记录', Icons.lock_outline, AppColors.typeColors['password']!, 'password'),
              _buildAddOption(context, '图片', Icons.image_outlined, AppColors.typeColors['image']!, 'image'),
              _buildAddOption(context, '文件', Icons.insert_drive_file_outlined, AppColors.typeColors['file']!, 'file'),
              _buildAddOption(context, '链接', Icons.link_outlined, AppColors.typeColors['link']!, 'link'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(BuildContext context, String label, IconData icon, Color color, String type) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EntryEditorScreen(entryType: type)),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  _StatItem(this.label, this.icon, this.color, this.count);