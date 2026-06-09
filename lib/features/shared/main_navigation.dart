import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../categories/categories_screen.dart';
import '../passwords/passwords_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    PasswordsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: AppColors.primary),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outlined),
            selectedIcon: Icon(Icons.lock, color: AppColors.primary),
            label: '密码箱',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
