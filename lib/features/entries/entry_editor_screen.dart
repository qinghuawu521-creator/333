import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/entry.dart';
import '../../core/models/category.dart';
import '../../core/models/tag.dart';
import '../../core/database/database_helper.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  final String entryType;
  final Entry? existingEntry;

  const EntryEditorScreen({
    super.key,
    required this.entryType,
    this.existingEntry,
  });

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();

  String? _selectedCategoryId;
  List<String> _selectedTagIds = [];
  bool _isStarred = false;
  bool _isEncrypted = false;
  Map<String, dynamic> _customFields = {};
  String? _filePath;
  String? _fileName;
  int? _fileSize;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      _titleController.text = e.title;
      _contentController.text = e.content ?? '';
      _urlController.text = e.url ?? '';
      _selectedCategoryId = e.categoryId;
      _selectedTagIds = List.from(e.tagIds);
      _isStarred = e.isStarred;
      _isEncrypted = e.isEncrypted;
      _customFields = Map.from(e.customFields);
      _filePath = e.filePath;
      _fileName = e.fileName;
      _fileSize = e.fileSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null ? '编辑记录' : '新建${_getTypeName(widget.entryType)}'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '输入标题',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null,
            ),
            const SizedBox(height: 16),

            // Type-specific fields
            if (widget.entryType == 'text' || widget.entryType == 'password') ...[
              TextFormField(
                controller: _contentController,
                maxLines: widget.entryType == 'password' ? 1 : 8,
                decoration: InputDecoration(
                  labelText: widget.entryType == 'password' ? '密码/内容' : '内容',
                  hintText: widget.entryType == 'password' ? '输入密码或账号信息' : '输入内容',
                  alignLabelWithHint: widget.entryType != 'password',
                ),
              ),
            ],

            if (widget.entryType == 'link') ...[
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: '链接地址',
                  hintText: 'https://',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '请输入链接';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '链接描述（可选）',
                ),
              ),
            ],

            if (widget.entryType == 'image') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200, style: BorderStyle.solid),
                ),
                child: _filePath != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(_filePath!, height: 200, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: AppColors.neutral200,
                                child: Center(child: Icon(Icons.image, size: 48, color: AppColors.neutral400)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('重新选择'),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.neutral400),
                            const SizedBox(height: 8),
                            Text('点击选择图片', style: TextStyle(color: AppColors.neutral500)),
                          ],
                        ),
                      ),
              ),
            ],

            if (widget.entryType == 'file') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: _fileName != null
                    ? Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: AppColors.warning, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (_fileSize != null)
                                  Text(_formatFileSize(_fileSize!), style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _pickFile,
                            child: const Text('重新选择'),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: _pickFile,
                        child: Column(
                          children: [
                            Icon(Icons.upload_file, size: 48, color: AppColors.neutral400),
                            const SizedBox(height: 8),
                            Text('点击选择文件', style: TextStyle(color: AppColors.neutral500)),
                            const SizedBox(height: 4),
                            Text(
                              '支持 PDF、Word、Excel、TXT、ZIP',
                              style: TextStyle(fontSize: 12, color: AppColors.neutral400),
                            ),
                          ],
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 20),

            // Category selector
            categories.when(
              data: (cats) => _buildCategorySelector(cats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Tags selector
            tags.when(
              data: (allTags) => _buildTagSelector(allTags),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),

            // Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('收藏'),
                    subtitle: const Text('标记为收藏'),
                    value: _isStarred,
                    onChanged: (v) => setState(() => _isStarred = v),
                    secondary: Icon(Icons.star, color: _isStarred ? AppColors.warning : AppColors.neutral400),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppColors.neutral200),
                  SwitchListTile(
                    title: const Text('加密存储'),
                    subtitle: const Text('使用 AES-256 加密'),
                    value: _isEncrypted,
                    onChanged: (v) => setState(() => _isEncrypted = v),
                    secondary: Icon(Icons.lock, color: _isEncrypted ? AppColors.error : AppColors.neutral400),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Custom fields
            _buildCustomFields(),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('分类', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryId,
              hint: Text('选择分类', style: TextStyle(color: AppColors.neutral400)),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('无分类')),
                ...categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelector(List<Tag> allTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allTags.map((tag) {
              final isSelected = _selectedTagIds.contains(tag.id);
              final color = tag.color != null
                  ? AppColors.hexToColor(tag.color!)
                  : AppColors.primary;
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTagIds.add(tag.id);
                    } else {
                      _selectedTagIds.remove(tag.id);
                    }
                  });
                },
                selectedColor: color.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? color : AppColors.neutral600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? color.withOpacity(0.3) : AppColors.neutral300,
                ),
              );
            }),
            ActionChip(
              label: const Text('+ 新标签'),
              onPressed: () => _showAddTagDialog(),
              labelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('自定义字段', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
            TextButton(
              onPressed: _addCustomField,
              child: const Text('+ 添加字段'),
            ),
          ],
        ),
        ..._customFields.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(entry.key, style: TextStyle(fontSize: 13, color: AppColors.neutral600)),
              ),
              Expanded(
                flex: 3,
                child: Text(entry.value.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: AppColors.neutral400),
                onPressed: () => setState(() => _customFields.remove(entry.key)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _addCustomField() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加字段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyController, decoration: const InputDecoration(labelText: '字段名')),
            const SizedBox(height: 12),
            TextField(controller: valueController, decoration: const InputDecoration(labelText: '值')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                setState(() => _customFields[keyController.text] = valueController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: '标签名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final tag = Tag(name: nameController.text.trim());
              await DatabaseHelper.instance.insertTag(tag);
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(tagsProvider);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _filePath = image.path;
        _fileName = image.name;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _filePath = file.path;
        _fileName = file.name;
        _fileSize = file.size;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = Entry(
      id: widget.existingEntry?.id,
      title: _titleController.text.trim(),
      type: widget.entryType,
      content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      categoryId: _selectedCategoryId,
      filePath: _filePath,
      fileName: _fileName,
      fileSize: _fileSize,
      url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      isStarred: _isStarred,
      isEncrypted: _isEncrypted,
      tagIds: _selectedTagIds,
      customFields: _customFields,
      createdAt: widget.existingEntry?.createdAt,
    );

    if (widget.existingEntry != null) {
      await DatabaseHelper.instance.updateEntry(entry);
    } else {
      await DatabaseHelper.instance.insertEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
      refreshEntries(ref);
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'text': return '文本记录';
      case 'password': return '密码记录';
      case 'image': return '图片';
      case 'file': return '文件';
      case 'link': return '链接';
      default: return '记录';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
