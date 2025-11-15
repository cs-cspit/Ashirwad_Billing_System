import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/supabase_service.dart';
import 'invoices_list_screen.dart';
import 'create_invoice_screen.dart';
import 'add_product_screen.dart';
import 'add_customer_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'customer_management_screen.dart';
import 'product_management_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardContent(),
    const InvoicesListScreen(),
    const SettingsScreen(),
  ];

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMenuHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: !isDesktop ? AppBar(
        title: const Text('Ashirwad Industries'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ) : null,
      drawer: !isDesktop ? _buildDrawer(context) : null,
      body: SafeArea(
        child: isDesktop ? Row(
          children: [
            // Desktop Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.business, color: AppTheme.primaryColor),
                        ),
                        SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ashirwad Industries',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Billing Management',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Navigation
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      children: [
                        _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                        _buildMenuItem(Icons.receipt_long, 'Invoices', 1),
                        _buildMenuItem(Icons.settings, 'Settings', 2),
                        const SizedBox(height: AppConstants.paddingMedium),
                        const Divider(),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildMenuHeader('Quick Actions'),
                        _buildQuickAction(Icons.add_circle, 'New Invoice', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                          );
                        }),
                        _buildQuickAction(Icons.person_add, 'Add Customer', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                          );
                        }),
                        _buildQuickAction(Icons.add_box, 'Add Product', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddProductScreen()),
                          );
                        }),
                        const SizedBox(height: AppConstants.paddingMedium),
                        const Divider(),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildMenuHeader('Management'),
                        _buildQuickAction(Icons.people, 'Customers', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CustomerManagementScreen()),
                          );
                        }),
                        _buildQuickAction(Icons.inventory_2, 'Products', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProductManagementScreen()),
                          );
                        }),
                        _buildQuickAction(Icons.analytics, 'Reports', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportsScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  // Logout Button
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Desktop Main Content
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ) : _screens[_selectedIndex], // Mobile: just show content
      ),
    );
  }

  // Drawer for mobile
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: const SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.business, color: AppTheme.primaryColor),
                  ),
                  SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ashirwad Industries',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Billing Management',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              children: [
                _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                _buildMenuItem(Icons.receipt_long, 'Invoices', 1),
                _buildMenuItem(Icons.settings, 'Settings', 2),
                const SizedBox(height: AppConstants.paddingMedium),
                const Divider(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildMenuHeader('Quick Actions'),
                _buildQuickAction(Icons.add_circle, 'New Invoice', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                  );
                }),
                _buildQuickAction(Icons.person_add, 'Add Customer', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                  );
                }),
                _buildQuickAction(Icons.add_box, 'Add Product', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  );
                }),
                const SizedBox(height: AppConstants.paddingMedium),
                const Divider(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildMenuHeader('Management'),
                _buildQuickAction(Icons.people, 'Customers', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerManagementScreen()),
                  );
                }),
                _buildQuickAction(Icons.inventory_2, 'Products', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductManagementScreen()),
                  );
                }),
                _buildQuickAction(Icons.analytics, 'Reports', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                }),
              ],
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard Content Widget
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final data = await SupabaseService.getDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppConstants.paddingMedium),
              Text('Loading dashboard data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Failed to load dashboard data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.2),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Updated: ${DateTime.now().toString().split(' ')[0]}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadDashboardData,
                                tooltip: 'Refresh',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard Overview',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadDashboardData,
                                tooltip: 'Refresh',
                              ),
                              const SizedBox(width: AppConstants.paddingSmall),
                              Text(
                                'Last updated: ${DateTime.now().toString().split('.')[0]}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
              },
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards - Responsive Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 800;
                      final cardWidth = isSmallScreen 
                          ? constraints.maxWidth 
                          : (constraints.maxWidth - 30) / 4;
                      
                      return Wrap(
                        spacing: AppConstants.paddingMedium,
                        runSpacing: AppConstants.paddingMedium,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? double.infinity : cardWidth,
                            child: _buildStatsCard(
                              'Total Revenue',
                              '₹${_dashboardData?['totalRevenue']?.toString() ?? '0.00'}',
                              Icons.currency_rupee,
                              Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : cardWidth,
                            child: _buildStatsCard(
                              'Total Customers',
                              _dashboardData?['totalCustomers']?.toString() ?? '0',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : cardWidth,
                            child: _buildStatsCard(
                              'Total Products',
                              _dashboardData?['totalProducts']?.toString() ?? '0',
                              Icons.inventory_2,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : cardWidth,
                            child: _buildStatsCard(
                              'Total Invoices',
                              _dashboardData?['totalInvoices']?.toString() ?? '0',
                              Icons.receipt_long,
                              Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Recent Activity - Responsive Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 800;
                      
                      if (isSmallScreen) {
                        return Column(
                          children: [
                            _buildRecentInvoices(),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildQuickStats(),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildTopProducts(),
                          ],
                        );
                      }
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recent Invoices
                          Expanded(
                            flex: 2,
                            child: _buildRecentInvoices(),
                          ),
                          
                          const SizedBox(width: AppConstants.paddingMedium),
                          
                          // Quick Stats
                          Expanded(
                            child: Column(
                              children: [
                                _buildQuickStats(),
                                const SizedBox(height: AppConstants.paddingMedium),
                                _buildTopProducts(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices() {
    final recentInvoices = _dashboardData?['recentInvoices'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Invoices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          if (recentInvoices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingLarge),
                child: Text(
                  'No recent invoices found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentInvoices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final invoice = recentInvoices[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.receipt, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    'Invoice #${invoice['invoiceNumber'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Customer: ${invoice['customerName'] ?? 'Unknown'}\n'
                    'Date: ${invoice['invoiceDate'] ?? 'N/A'}',
                  ),
                  trailing: Text(
                    '₹${invoice['totalAmount']?.toString() ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  isThreeLine: true,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildQuickStatItem('Today\'s Revenue', '₹${_dashboardData?['todayRevenue']?.toString() ?? '0.00'}'),
          _buildQuickStatItem('This Month', '₹${_dashboardData?['monthRevenue']?.toString() ?? '0.00'}'),
          _buildQuickStatItem('Pending Invoices', _dashboardData?['pendingInvoices']?.toString() ?? '0'),
          _buildQuickStatItem('Overdue Invoices', _dashboardData?['overdueInvoices']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final topProducts = _dashboardData?['topProducts'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          if (topProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingMedium),
                child: Text(
                  'No product data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = topProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    product['name'] ?? 'Unknown Product',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Sales: ${product['salesCount'] ?? 0}'),
                  trailing: Text(
                    '₹${product['revenue']?.toString() ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
