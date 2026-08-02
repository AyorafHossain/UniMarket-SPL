import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardStats();
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1E3A5F),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, int> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    List<PieChartSectionData> sections = [];
    int index = 0;
    categories.forEach((name, count) {
      final color = colors[index % colors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$count',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(categories.length, (idx) {
            final entry = categories.entries.elementAt(idx);
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.key,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOrdersBarChart(Map<String, int> statusData) {
    // Fill dummy values for missing keys to make chart consistent
    final pending = (statusData['pending_payment'] ?? 0) + (statusData['pending'] ?? 0);
    final paid = statusData['paid'] ?? 0;
    final cancelled = (statusData['cancelled'] ?? 0) + (statusData['failed'] ?? 0);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: [pending, paid, cancelled].reduce((a, b) => a > b ? a : b).toDouble() + 2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
                  Widget text;
                  switch (value.toInt()) {
                    case 0:
                      text = const Text('Pending', style: style);
                      break;
                    case 1:
                      text = const Text('Paid', style: style);
                      break;
                    case 2:
                      text = const Text('Failed', style: style);
                      break;
                    default:
                      text = const Text('', style: style);
                      break;
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: text,
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: pending.toDouble(),
                  color: Colors.amber,
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: paid.toDouble(),
                  color: Colors.green,
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: cancelled.toDouble(),
                  color: Colors.red,
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentExchangePieChart(int rentRequests, int exchangeRequests) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.teal,
              value: rentRequests.toDouble(),
              title: 'Rent ($rentRequests)',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: Colors.indigo,
              value: exchangeRequests.toDouble(),
              title: 'Exchange ($exchangeRequests)',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
          centerSpaceRadius: 30,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${provider.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final stats = provider.stats;
    if (stats == null) {
      return const Center(child: Text('No statistical data fetched.'));
    }

    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 1200
        ? 4
        : size.width > 800
            ? 3
            : size.width > 600
                ? 2
                : 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for Quick statistics
          GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Total Users',
                value: '${stats.totalUsers}',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(1),
              ),
              _buildStatCard(
                title: 'Total Products',
                value: '${stats.totalProducts}',
                icon: Icons.storefront,
                color: Colors.indigo,
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(2),
              ),
              _buildStatCard(
                title: 'Total Orders',
                value: '${stats.totalOrders}',
                icon: Icons.shopping_cart,
                color: Colors.green,
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(3),
              ),
              _buildStatCard(
                title: 'Total Revenue',
                value: '৳${stats.totalRevenue.toStringAsFixed(2)}',
                icon: Icons.monetization_on,
                color: const Color(0xFFD4A017),
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(3),
              ),
              _buildStatCard(
                title: 'Rent Requests',
                value: '${stats.totalRentRequests}',
                icon: Icons.key,
                color: Colors.teal,
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(4),
              ),
              _buildStatCard(
                title: 'Exchange Requests',
                value: '${stats.totalExchangeRequests}',
                icon: Icons.swap_horiz,
                color: Colors.deepOrange,
                onTap: () => context.read<NavigationProvider>().setSelectedIndex(5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Chart layouts
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // Chart 1: Category distribution
              Container(
                width: size.width > 1200 ? (size.width - 320) / 2 : size.width - 48,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products by Category',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCategoryChart(stats.productsByCategory),
                  ],
                ),
              ),
              // Chart 2: Orders Overview
              Container(
                width: size.width > 1200 ? (size.width - 320) / 2 : size.width - 48,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOrdersBarChart(stats.ordersStatus),
                  ],
                ),
              ),
              // Chart 3: Rent & Exchange distribution
              Container(
                width: size.width > 1200 ? (size.width - 320) / 2 : size.width - 48,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent vs Exchange Requests',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRentExchangePieChart(stats.totalRentRequests, stats.totalExchangeRequests),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
