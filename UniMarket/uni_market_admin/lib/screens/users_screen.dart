import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        backgroundImage: user.profilePic.isNotEmpty
                            ? NetworkImage(user.profilePic)
                            : null,
                        child: user.profilePic.isEmpty
                            ? const Icon(Icons.person, size: 36, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A5F),
                              ),
                            ),
                            Text(
                              user.email,
                              style: GoogleFonts.inter(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Role', user.role.toUpperCase()),
                  _buildDetailRow('University', user.university),
                  _buildDetailRow('University Email', user.universityEmail),
                  _buildDetailRow('Department', user.department),
                  _buildDetailRow('Phone Number', user.phoneNumber),
                  _buildDetailRow('Status', user.isActive ? 'Active' : 'Banned',
                      valueColor: user.isActive ? Colors.green : Colors.red),
                  _buildDetailRow('Auth Provider', user.authProvider.toUpperCase()),
                  _buildDetailRow('Email Verified', user.isEmailVerified ? 'Yes' : 'No',
                      valueColor: user.isEmailVerified ? Colors.green : Colors.amber),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUserProducts(user);
                        },
                        icon: const Icon(Icons.storefront),
                        label: const Text('View Listed Products'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(user.isActive ? 'Ban User' : 'Activate User'),
                              content: Text(
                                'Are you sure you want to ${user.isActive ? 'ban' : 'activate'} ${user.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: user.isActive ? Colors.red : Colors.green,
                                  ),
                                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _userService.updateUserStatus(user.id, !user.isActive);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('User status updated successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(user.isActive ? Icons.block : Icons.check_circle, color: Colors.white),
                        label: Text(
                          user.isActive ? 'Ban Account' : 'Activate Account',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isActive ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUserProducts(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Products by ${user.name}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<ProductModel>>(
                    future: _productService.getProductsBySeller(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return const Center(child: Text('No products listed by this user.'));
                      }

                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(product.imageUrls.first),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Category: ${product.category}\nPrice: ৳${product.price}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: product.approvalStatus == 'approved'
                                        ? Colors.green.shade100
                                        : product.approvalStatus == 'pending'
                                            ? Colors.orange.shade100
                                            : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    product.approvalStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: product.approvalStatus == 'approved'
                                          ? Colors.green.shade800
                                          : product.approvalStatus == 'pending'
                                              ? Colors.orange.shade800
                                              : Colors.red.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: GoogleFonts.inter(
                color: valueColor ?? const Color(0xFF1E3A5F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Users Directory',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          'Users Directory',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _userService.getUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading users: ${snapshot.error}'));
                    }

                    var users = snapshot.data ?? [];
                    if (_searchQuery.isNotEmpty) {
                      users = users.where((u) {
                        return u.name.toLowerCase().contains(_searchQuery) ||
                            u.email.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (users.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }

                    return _buildUsersList(users, isMobile);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users, bool isMobile) {
    if (isMobile) {
      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user.profilePic.isNotEmpty
                            ? NetworkImage(user.profilePic)
                            : null,
                        child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isActive ? 'Active' : 'Banned',
                          style: TextStyle(color: user.isActive ? Colors.green.shade800 : Colors.red.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Details'),
                        onPressed: () => _showUserDetails(user),
                      ),
                      OutlinedButton.icon(
                        icon: Icon(
                          user.isActive ? Icons.block : Icons.check_circle,
                          size: 16,
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                        label: Text(
                          user.isActive ? 'Ban' : 'Activate',
                          style: TextStyle(color: user.isActive ? Colors.red : Colors.green),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(user.isActive ? 'Ban User' : 'Activate User'),
                              content: Text('Are you sure you want to ${user.isActive ? 'ban' : 'activate'} ${user.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? Colors.red : Colors.green),
                                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _userService.updateUserStatus(user.id, !user.isActive);
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A5F).withValues(alpha: 0.05)),
            columns: [
              DataColumn(label: Text('Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('University', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: user.profilePic.isNotEmpty
                              ? NetworkImage(user.profilePic)
                              : null,
                          child: user.profilePic.isEmpty ? const Icon(Icons.person, size: 16) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(user.name),
                      ],
                    ),
                  ),
                  DataCell(Text(user.email)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(user.university)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isActive ? 'Active' : 'Banned',
                        style: TextStyle(
                          color: user.isActive ? Colors.green.shade800 : Colors.red.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Color(0xFF1E3A5F)),
                          onPressed: () => _showUserDetails(user),
                        ),
                        IconButton(
                          icon: Icon(
                            user.isActive ? Icons.block : Icons.check_circle,
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(user.isActive ? 'Ban User' : 'Activate User'),
                                content: Text('Are you sure you want to ${user.isActive ? 'ban' : 'activate'} ${user.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: user.isActive ? Colors.red : Colors.green,
                                    ),
                                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _userService.updateUserStatus(user.id, !user.isActive);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
