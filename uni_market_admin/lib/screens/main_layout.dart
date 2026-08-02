import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

import '../providers/navigation_provider.dart';

// Screens
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'rent_requests_screen.dart';
import 'exchange_requests_screen.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'pending_payouts_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<String> _titles = [
    'Dashboard Overview',
    'User Management',
    'Product Approval & Listings',
    'Order Management',
    'Rent Management',
    'Exchange Requests',
    'Category Management',
    'Profile Settings',
    'Pending Payouts'
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const ProductsScreen(),
    const OrdersScreen(),
    const RentRequestsScreen(),
    const ExchangeRequestsScreen(),
    const CategoriesScreen(),
    const ProfileScreen(),
    const PendingPayoutsScreen(),
  ];

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final selectedIndex = context.watch<NavigationProvider>().selectedIndex;
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD4A017).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFD4A017) : Colors.white70,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          context.read<NavigationProvider>().setSelectedIndex(index);
          if (MediaQuery.of(context).size.width <= 900) {
            Navigator.pop(context); // Close mobile drawer
          }
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final admin = authProvider.currentAdmin;

    return Container(
      width: 260,
      color: const Color(0xFF0F2027),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFD4A017).withValues(alpha: 0.2),
                  backgroundImage: admin?.profilePic.isNotEmpty == true
                      ? NetworkImage(admin!.profilePic)
                      : null,
                  child: admin?.profilePic.isEmpty != false
                      ? const Icon(Icons.admin_panel_settings, size: 36, color: Color(0xFFD4A017))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  admin?.name ?? 'Admin Portal',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  admin?.email ?? 'admin@unimarket.com',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sidebar Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(0, Icons.dashboard_outlined, 'Dashboard'),
                  _buildMenuItem(1, Icons.people_outline, 'Users'),
                  _buildMenuItem(2, Icons.fact_check_outlined, 'Products Approval'),
                  _buildMenuItem(3, Icons.shopping_bag_outlined, 'Orders'),
                  _buildMenuItem(4, Icons.car_rental_outlined, 'Rent Requests'),
                  _buildMenuItem(5, Icons.swap_horiz_outlined, 'Exchange Requests'),
                  _buildMenuItem(6, Icons.category_outlined, 'Categories'),
                  _buildMenuItem(7, Icons.manage_accounts_outlined, 'Profile Settings'),
                  _buildMenuItem(8, Icons.payments_outlined, 'Pending Payouts'),
                ],
              ),
            ),
          ),
          // Logout item
          const Divider(color: Colors.white10, height: 1),
          Container(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                'Logout',
                style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out of UniMarket Admin?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Logout', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final selectedIndex = context.watch<NavigationProvider>().selectedIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context)),
      appBar: AppBar(
        title: Text(
          _titles[selectedIndex],
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
      ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _screens[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
