import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/template.dart';
import '../../core/database/database_helper.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTemplateEditor(context, null),
          ),
        ],
      ),
      body: templates.when(
        data: (list) => list.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                itemBuilder: (context, index) => _buildTemplateTile(context, list[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text('还没有模板', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral500)),
          const SizedBox(height: 8),
          Text('创建模板可以快速录入重复类型的数据', style: TextStyle(color: AppColors.neutral400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showTemplateEditor(context, null),
            icon: const Icon(Icons.add),
            label: const Text('创建模板'),
          ),
          const SizedBox(height: 16),
          // Preset templates
          TextButton(
            onPressed: _addPresetTemplates,
            child: const Text('添加预设模板'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, Template template) {
    final color = template.color != null
        ? AppColors.hexToColor(template.color!)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTemplateEditor(context, template),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.description_outlined, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(
                            '${template.fields.length} 个字段',
                            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showTemplateEditor(context, template);
                        } else if (value == 'delete') {
                          _deleteTemplate(context, template);
                        }
                      },
                    ),
                  ],
                ),
                if (template.fields.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: template.fields.take(5).map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(f.name, style: TextStyle(fontSize: 11, color: AppColors.neutral600)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplateEditor(BuildContext context, Template? template) {
    final nameController = TextEditingController(text: template?.name ?? '');
    String entryType = template?.entryType ?? 'text';
    List<FieldDefinition> fields = template?.fields.map((f) => FieldDefinition(
      name: f.name,
      type: f.type,
      isRequired: f.isRequired,
      placeholder: f.placeholder,
    )).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template != null ? '编辑模板' : '新建模板',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '模板名称', hintText: '例如：网站账号'),
                  ),
                  const SizedBox(height: 16),
                  // Entry type
                  Text('记录类型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['text', 'password', 'link'].map((type) {
                      return ChoiceChip(
                        label: Text(_getTypeName(type)),
                        selected: entryType == type,
                        onSelected: (_) => setModalState(() => entryType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('字段列表', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            fields.add(FieldDefinition(name: '', type: 'text'));
                          });
                        },
                        child: const Text('+ 添加字段'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...fields.asMap().entries.map((entry) {
                    final i = entry.key;
                    final field = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(text: field.name),
                              decoration: const InputDecoration(
                                labelText: '字段名',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (v) => field.name = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: field.type,
                              isDense: true,
                              decoration: const InputDecoration(
                                labelText: '类型',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'text', child: Text('文本')),
                                DropdownMenuItem(value: 'multiline', child: Text('多行')),
                                DropdownMenuItem(value: 'number', child: Text('数字')),
                                DropdownMenuItem(value: 'email', child: Text('邮箱')),
                                DropdownMenuItem(value: 'phone', child: Text('电话')),
                                DropdownMenuItem(value: 'url', child: Text('链接')),
                                DropdownMenuItem(value: 'date', child: Text('日期')),
                              ],
                              onChanged: (v) => setModalState(() => field.type = v ?? 'text'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
                            onPressed: () => setModalState(() => fields.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final tpl = Template(
                          id: template?.id,
                          name: nameController.text.trim(),
                          entryType: entryType,
                          fields: fields.where((f) => f.name.isNotEmpty).toList(),
                        );
                        if (template != null) {
                          await DatabaseHelper.instance.updateTemplate(tpl);
                        } else {
                          await DatabaseHelper.instance.insertTemplate(tpl);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(templatesProvider);
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteTemplate(BuildContext context, Template template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除「${template.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await DatabaseHelper.instance.deleteTemplate(template.id);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(templatesProvider);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPresetTemplates() async {
    final presets = [
      Template(
        name: '网站账号',
        entryType: 'password',
        fields: [
          FieldDefinition(name: '网站', type: 'url', placeholder: 'https://'),
          FieldDefinition(name: '账号', type: 'text'),
          FieldDefinition(name: '密码', type: 'text'),
          FieldDefinition(name: '邮箱', type: 'email'),
          FieldDefinition(name: '手机号', type: 'phone'),
          FieldDefinition(name: '备注', type: 'multiline'),
        ],
      ),
      Template(
        name: '客户信息',
        entryType: 'text',
        fields: [
          FieldDefinition(name: '姓名', type: 'text'),
          FieldDefinition(name: '电话', type: 'phone'),
          FieldDefinition(name: '来源', type: 'text'),
          FieldDefinition(name: '成交金额', type: 'number'),
          FieldDefinition(name: '备注', type: 'multiline'),
        ],
      ),
      Template(
        name: '设备信息',
        entryType: 'text',
        fields: [
          FieldDefinition(name: '设备名称', type: 'text'),
          FieldDefinition(name: '型号', type: 'text'),
          FieldDefinition(name: '购买时间', type: 'date'),
          FieldDefinition(name: '价格', type: 'number'),
          FieldDefinition(name: '备注', type: 'multiline'),
        ],
      ),
      Template(
        name: '银行卡',
        entryType: 'text',
        fields: [
          FieldDefinition(name: '银行', type: 'text'),
          FieldDefinition(name: '卡号', type: 'text'),
          FieldDefinition(name: '持卡人', type: 'text'),
          FieldDefinition(name: '开户行', type: 'text'),
          FieldDefinition(name: '备注', type: 'multiline'),
        ],
      ),
    ];

    for (final preset in presets) {
      await DatabaseHelper.instance.insertTemplate(preset);
    }

    if (mounted) {
      ref.invalidate(templatesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加预设模板')),
      );
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'text': return '文本';
      case 'password': return '密码';
      case 'link': return '链接';
      default: return type;
    }
  }
}
