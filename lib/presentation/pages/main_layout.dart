import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'master_data_page.dart';
import 'slip_gaji_page.dart';
import 'invoice_page.dart';
import '../../core/constants/colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedSidebarIndex = 0; // Default to Dashboard

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
            color: AppColors.textLight.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Halaman $title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fitur ini sedang dalam pengembangan.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const SlipGajiPage();
      case 2:
        return const InvoicePage();
      case 3:
        return const MasterDataPage();
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
            color: AppColors.primary,
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

                const SizedBox(height: 8),

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
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedSidebarIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? item['activeIcon'] : item['icon'],
                                        color: isSelected ? Colors.white : Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
