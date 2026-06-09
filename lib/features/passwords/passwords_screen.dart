import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/password_entry.dart';
import '../../core/services/security_service.dart';
import '../../core/database/database_helper.dart';

class PasswordsScreen extends ConsumerStatefulWidget {
  const PasswordsScreen({super.key});

  @override
  ConsumerState<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends ConsumerState<PasswordsScreen> {
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final passwordsAsync = ref.watch(passwordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索密码...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('密码保险箱'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            }),
          ),
        ],
      ),
      body: passwordsAsync.when(
        data: (passwords) {
          final filtered = _searchQuery.isEmpty
              ? passwords
              : passwords.where((p) =>
                  p.platform.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  p.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (p.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildPasswordTile(context, filtered[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPasswordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPasswordTile(BuildContext context, PasswordEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPasswordDetail(context, entry),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.key_rounded, color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.platform,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.username,
                        style: TextStyle(fontSize: 13, color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                // Strength indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStrengthColor(entry.passwordStrength).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.strengthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStrengthColor(entry.passwordStrength),
                    ),
                  ),
                ),
                if (entry.isStarred) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outlined, size: 64, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text('还没有密码记录', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.neutral500)),
          const SizedBox(height: 8),
          Text('点击 + 添加密码', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.neutral400)),
        ],
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    if (strength <= 1) return AppColors.error;
    if (strength <= 2) return AppColors.warning;
    if (strength <= 3) return AppColors.info;
    return AppColors.success;
  }

  void _showPasswordDetail(BuildContext context, PasswordEntry entry) {
    final security = SecurityService();
    bool passwordVisible = false;
    String? decryptedPassword;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.neutral300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.key_rounded, color: AppColors.error, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.platform, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              Text(entry.strengthLabel, style: TextStyle(fontSize: 12, color: _getStrengthColor(entry.passwordStrength))),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(entry.isStarred ? Icons.star : Icons.star_border, color: AppColors.warning),
                          onPressed: () async {
                            final updated = entry.copyWith(isStarred: !entry.isStarred);
                            await DatabaseHelper.instance.updatePassword(updated);
                            if (context.mounted) {
                              Navigator.pop(context);
                              refreshPasswords(ref);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Fields
                    _buildDetailField(context, '平台', entry.platform, copyable: true),
                    _buildDetailField(context, '账号', entry.username, copyable: true),
                    _buildPasswordField(context, entry, passwordVisible, decryptedPassword, (visible) async {
                      if (visible && decryptedPassword == null) {
                        try {
                          decryptedPassword = security.decryptText(entry.encryptedPassword);
                        } catch (_) {
                          decryptedPassword = entry.encryptedPassword;
                        }
                      }
                      setModalState(() => passwordVisible = visible);
                    }),
                    if (entry.email != null && entry.email!.isNotEmpty)
                      _buildDetailField(context, '邮箱', entry.email!, copyable: true),
                    if (entry.phone != null && entry.phone!.isNotEmpty)
                      _buildDetailField(context, '手机号', entry.phone!, copyable: true),
                    if (entry.verificationInfo != null && entry.verificationInfo!.isNotEmpty)
                      _buildDetailField(context, '验证码信息', entry.verificationInfo!, copyable: true),
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      _buildDetailField(context, '备注', entry.notes!),
                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('编辑'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () async {
                              await DatabaseHelper.instance.deletePassword(entry.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                refreshPasswords(ref);
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('删除'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailField(BuildContext context, String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              if (copyable)
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已复制$label'), duration: const Duration(seconds: 1)),
                    );
                  },
                ),
            ],
          ),
          Divider(color: AppColors.neutral200),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context,
    PasswordEntry entry,
    bool isVisible,
    String? decrypted,
    Function(bool) onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('密码', style: TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  isVisible ? (decrypted ?? '••••••••') : '••••••••',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: isVisible ? 'monospace' : null,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.neutral500),
                onPressed: () => onToggle(!isVisible),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: AppColors.primary),
                onPressed: () async {
                  final password = decrypted ??= SecurityService().decryptText(entry.encryptedPassword);
                  Clipboard.setData(ClipboardData(text: password));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制密码'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          Divider(color: AppColors.neutral200),
        ],
      ),
    );
  }

  void _showAddPasswordDialog(BuildContext context) {
    final platformController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    bool obscurePassword = true;

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
                  Text('添加密码', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: platformController,
                    decoration: const InputDecoration(labelText: '平台名称', hintText: '例如：Google'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: '账号', hintText: '用户名/邮箱/手机号'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                          ),
                          IconButton(
                            icon: const Icon(Icons.casino, size: 20),
                            onPressed: () {
                              final pwd = _generateRandomPassword();
                              passwordController.text = pwd;
                              setModalState(() => obscurePassword = false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: '邮箱', hintText: '可选'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: '手机号', hintText: '可选'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '备注', hintText: '可选'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (platformController.text.isEmpty || usernameController.text.isEmpty || passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请填写平台、账号和密码')),
                          );
                          return;
                        }
                        final security = SecurityService();
                        final encrypted = security.encryptText(passwordController.text);
                        final strength = PasswordEntry.calculateStrength(passwordController.text);
                        final entry = PasswordEntry(
                          platform: platformController.text.trim(),
                          username: usernameController.text.trim(),
                          encryptedPassword: encrypted,
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          passwordStrength: strength,
                        );
                        await DatabaseHelper.instance.insertPassword(entry);
                        if (context.mounted) {
                          Navigator.pop(context);
                          refreshPasswords(ref);
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

  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = List.generate(16, (i) => chars[(DateTime.now().microsecondsSinceEpoch + i * 7) % chars.length]);
    return random.join();
  }
}
