import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/helpers.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  List<FileSystemEntity> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backups = await _backupService.listBackups();
    setState(() => _backups = backups);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份与恢复')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Backup section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.backup, color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('创建备份', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('备份所有数据到本地文件', style: TextStyle(fontSize: 13, color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isBackingUp ? null : _createBackup,
                    icon: _isBackingUp
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.backup),
                    label: Text(_isBackingUp ? '备份中...' : '立即备份'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restore section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restore, color: AppColors.info, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('恢复数据', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('从备份文件恢复数据', style: TextStyle(fontSize: 13, color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '恢复将覆盖当前所有数据，请先备份现有数据',
                          style: TextStyle(fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRestoring ? null : _restoreBackup,
                    icon: _isRestoring
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.restore),
                    label: Text(_isRestoring ? '恢复中...' : '选择备份文件恢复'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup history
          Text('备份历史', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          if (_backups.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.neutral300),
                  const SizedBox(height: 12),
                  Text('还没有备份记录', style: TextStyle(color: AppColors.neutral500)),
                ],
              ),
            )
          else
            ..._backups.map((backup) => _buildBackupTile(backup)),
        ],
      ),
    );
  }

  Widget _buildBackupTile(FileSystemEntity backup) {
    final stat = backup.statSync();
    final name = backup.path.split('/').last;
    final size = stat.size;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.archive_outlined, color: AppColors.success, size: 20),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          subtitle: Text(
            '${AppDateUtils.formatDateTime(stat.modified)} · ${FileUtils.formatFileSize(size)}',
            style: TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'restore', child: Text('恢复')),
              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (value) {
              if (value == 'restore') {
                _confirmRestore(backup.path);
              } else if (value == 'delete') {
                _confirmDelete(backup.path);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await _backupService.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份成功: $path'), backgroundColor: AppColors.success),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    _confirmRestore(filePath);
  }

  void _confirmRestore(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('恢复将覆盖当前所有数据。此操作不可撤销，确定继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isRestoring = true);
              try {
                await _backupService.restoreBackup(path);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('恢复成功'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('恢复失败: $e'), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                setState(() => _isRestoring = false);
              }
            },
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: const Text('确定要删除这个备份文件吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _backupService.deleteBackup(path);
              if (context.mounted) {
                Navigator.pop(context);
                _loadBackups();
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }