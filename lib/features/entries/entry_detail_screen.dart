import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/entry.dart';
import '../../core/database/database_helper.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(entryProvider(widget.entryId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          entryAsync.when(
            data: (entry) => entry == null
                ? const SizedBox()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(entry.isStarred ? Icons.star : Icons.star_border, color: AppColors.warning),
                        onPressed: () async {
                          await DatabaseHelper.instance.toggleStar(entry.id);
                          ref.invalidate(entryProvider(widget.entryId));
                          refreshEntries(ref);
                        },
                      ),
                      IconButton(
                        icon: Icon(entry.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: AppColors.primary),
                        onPressed: () async {
                          await DatabaseHelper.instance.togglePin(entry.id);
                          ref.invalidate(entryProvider(widget.entryId));
                          refreshEntries(ref);
                        },
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                          const PopupMenuItem(value: 'copy', child: Text('复制内容')),
                          const PopupMenuItem(value: 'share', child: Text('分享')),
                          const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (value) => _handleMenuAction(context, value, entry),
                      ),
                    ],
                  ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) => entry == null
            ? const Center(child: Text('记录不存在'))
            : _buildContent(context, entry),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Entry entry) {
    final typeColor = AppColors.typeColors[entry.type] ?? AppColors.neutral500;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getTypeIcon(entry.type), color: typeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.typeDisplayName,
                            style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(entry.createdAt),
                          style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content based on type
          if (entry.type == 'text' || entry.type == 'password') ...[
            if (entry.content != null && entry.content!.isNotEmpty) ...[
              _buildSectionTitle(context, '内容'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: SelectableText(
                  entry.content!,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
            ],
          ],

          if (entry.type == 'link') ...[
            _buildSectionTitle(context, '链接'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      entry.url ?? '',
                      style: TextStyle(fontSize: 14, color: AppColors.info),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.open_in_new, color: AppColors.info, size: 18),
                    onPressed: () {
                      // Open URL
                    },
                  ),
                ],
              ),
            ),
          ],

          if (entry.type == 'image') ...[
            if (entry.filePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    entry.filePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: AppColors.neutral400),
                            const SizedBox(height: 8),
                            Text('图片加载失败', style: TextStyle(color: AppColors.neutral500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],

          if (entry.type == 'file') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.insert_drive_file, color: AppColors.warning, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.fileName ?? '未知文件', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (entry.fileSize != null)
                          Text(_formatFileSize(entry.fileSize!), style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.open_in_new, color: AppColors.warning),
                    onPressed: () {
                      // Open file
                    },
                  ),
                ],
              ),
            ),
          ],

          // Custom fields
          if (entry.customFields.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle(context, '自定义字段'),
            const SizedBox(height: 8),
            ...entry.customFields.entries.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      field.key,
                      style: TextStyle(fontSize: 13, color: AppColors.neutral500, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            field.value.toString(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 16, color: AppColors.primary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: field.value.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已复制${field.key}'), duration: const Duration(seconds: 1)),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Metadata
          const SizedBox(height: 24),
          Divider(color: AppColors.neutral200),
          const SizedBox(height: 12),
          _buildMetadata(context, '创建时间', _formatDateTime(entry.createdAt)),
          _buildMetadata(context, '更新时间', _formatDateTime(entry.updatedAt)),
          if (entry.isStarred) _buildMetadata(context, '状态', '⭐ 已收藏'),
          if (entry.isPinned) _buildMetadata(context, '状态', '📌 已置顶'),

          // Action buttons
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.content ?? entry.url ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制内容'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Share
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('分享'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.neutral700,
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, Entry entry) {
    switch (action) {
      case 'edit':
        // Navigate to edit
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: entry.content ?? entry.url ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制内容'), duration: Duration(seconds: 1)),
        );
        break;
      case 'share':
        // Share
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: Text('确定要删除「${entry.title}」吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteEntry(entry.id);
                  if (mounted) {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    refreshEntries(ref);
                  }
                },
                child: const Text('删除'),
              ),
            ],
          ),
        );
        break;
    }
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
