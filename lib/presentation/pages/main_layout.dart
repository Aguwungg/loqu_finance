import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'master_data_page.dart';
import 'slip_gaji_page.dart';
import 'invoice_page.dart';
import '../../core/constants/colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedSidebarIndex = 0; // Default to Dashboard
  int? _hoveredIndex;

  final List<Map<String, dynamic>> _sidebarItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded},
    {'title': 'Buat Slip Gaji', 'icon': Icons.payments_outlined, 'activeIcon': Icons.payments_rounded},
    {'title': 'Buat Invoice', 'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long_rounded},
    {'title': 'Data Master', 'icon': Icons.dns_outlined, 'activeIcon': Icons.dns_rounded},
  ];

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: context.colors.textLight.withAlpha(128),
          ),
          SizedBox(height: 16),
          Text(
            'Halaman $title',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.colors.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur ini sedang dalam pengembangan.',
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return DashboardPage(
          onNavigateToPage: (index) {
            setState(() {
              _selectedSidebarIndex = index;
            });
          },
        );
      case 1:
        return SlipGajiPage();
      case 2:
        return InvoicePage();
      case 3:
        return MasterDataPage();
      default:
        final item = _sidebarItems[_selectedSidebarIndex];
        return _buildPlaceholder(item['title'], item['icon']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: context.colors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo/Header Sidebar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Main Sidebar Menu List
                Expanded(
                  child: Column(
                    children: [
                      // List Menu Items
                      Expanded(
                        child: ListView.builder(
                          itemCount: _sidebarItems.length,
                          itemBuilder: (context, index) {
                            final item = _sidebarItems[index];
                            final isSelected = _selectedSidebarIndex == index;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _hoveredIndex = index),
                                onExit: (_) => setState(() => _hoveredIndex = null),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedSidebarIndex = index;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade700
                                          : (_hoveredIndex == index ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? item['activeIcon'] : item['icon'],
                                          color: isSelected ? Colors.white : (_hoveredIndex == index ? Colors.white : Colors.white70),
                                          size: 20,
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            item['title'],
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : (_hoveredIndex == index ? Colors.white : Colors.white70),
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Theme Toggle Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dark Mode',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Switch(
                              value: ref.watch(themeModeProvider) == ThemeMode.dark,
                              onChanged: (val) {
                                ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                              },
                              activeThumbColor: Colors.blue.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: context.colors.background,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedSidebarIndex),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
