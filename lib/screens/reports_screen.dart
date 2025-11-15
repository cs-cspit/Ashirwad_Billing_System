import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/supabase_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year', 'Custom'];

  Map<String, dynamic> _reportSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCustomers = [];
  Map<String, int> _invoiceStatusCounts = {};
  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomerId;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DateTime? startDate;
      DateTime? endDate = DateTime.now();

      switch (_selectedPeriod) {
        case 'Today':
          startDate = DateTime(endDate.year, endDate.month, endDate.day);
          break;
        case 'This Week':
          startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
          break;
        case 'This Month':
          startDate = DateTime(endDate.year, endDate.month, 1);
          break;
        case 'This Quarter':
          final currentMonth = endDate.month;
          if (currentMonth >= 1 && currentMonth <= 3) {
            startDate = DateTime(endDate.year, 1, 1);
          } else if (currentMonth >= 4 && currentMonth <= 6) {
            startDate = DateTime(endDate.year, 4, 1);
          } else if (currentMonth >= 7 && currentMonth <= 9) {
            startDate = DateTime(endDate.year, 7, 1);
          } else {
            startDate = DateTime(endDate.year, 10, 1);
          }
          break;
        case 'This Year':
          startDate = DateTime(endDate.year, 1, 1);
          break;
        case 'Custom':
          // TODO: Implement custom date range picker
          break;
      }

      final summary = await SupabaseService.getReportSummary(
        startDate: startDate,
        endDate: endDate,
        customerId: _selectedCustomerId,
      );
      final topProducts = await SupabaseService.getTopProducts(
        startDate: startDate,
        endDate: endDate,
        customerId: _selectedCustomerId,
      );
      final topCustomers = await SupabaseService.getTopCustomers(
        startDate: startDate,
        endDate: endDate,
        customerId: _selectedCustomerId,
      );
      final invoiceCounts = await SupabaseService.getInvoiceStatusCounts(
        startDate: startDate,
        endDate: endDate,
        customerId: _selectedCustomerId,
      );

      // Load customers for company filter dropdown
      final customerRows = await SupabaseService.getCustomers();
      _customers = customerRows.map((c) => {'id': c.id, 'name': c.name}).toList();

      setState(() {
        _reportSummary = summary;
        _topProducts = topProducts;
        _topCustomers = topCustomers;
        _invoiceStatusCounts = invoiceCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadReports,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                            _loadReports();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            // Company filter
            _buildCompanyFilter(),
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Summary Stats
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildSummaryCard(),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Top Products
            Text(
              'Top Products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildTopProductsCard(),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Top Customers
            Text(
              'Top Customers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildTopCustomersCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalRevenue = (_reportSummary['totalRevenue'] ?? 0.0) is String 
      ? double.parse(_reportSummary['totalRevenue'] ?? '0.0')
      : (_reportSummary['totalRevenue'] ?? 0.0);
    final totalInvoices = _reportSummary['totalInvoices'] ?? 0;
    final paidInvoices = _invoiceStatusCounts['paid'] ?? 0;
    final pendingInvoices = _invoiceStatusCounts['pending'] ?? 0;
    final pendingAmount = (_reportSummary['pendingAmount'] ?? 0.0) is String
      ? double.parse(_reportSummary['pendingAmount'] ?? '0.0')
      : (_reportSummary['pendingAmount'] ?? 0.0);
    final collectedAmount = (_reportSummary['collectedAmount'] ?? 0.0) is String
      ? double.parse(_reportSummary['collectedAmount'] ?? '0.0')
      : (_reportSummary['collectedAmount'] ?? 0.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    '₹${totalRevenue.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Invoices',
                    totalInvoices.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Paid',
                    paidInvoices.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    pendingInvoices.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Collected',
                    '₹${collectedAmount.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Unpaid Total',
                    '₹${pendingAmount.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Company filter dropdown builder
  Widget _buildCompanyFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            const Icon(Icons.business, color: AppTheme.primaryColor),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: DropdownButton<String?>(
                value: _selectedCustomerId,
                isExpanded: true,
                hint: const Text('Filter by Company'),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem<String?>(value: null, child: const Text('All Companies')),
                  ..._customers.map((c) => DropdownMenuItem<String?>(value: c['id'] as String?, child: Text(c['name'] ?? ''))).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCustomerId = value;
                  });
                  _loadReports();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsCard() {
    if (_topProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text('No product data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: _topProducts.map((product) {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
              ),
              title: Text(product['name'] ?? 'Unknown'),
              subtitle: Text('Sales: ${product['total_quantity'] ?? 0}'),
              trailing: Text(
                '₹${(product['total_revenue'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopCustomersCard() {
    if (_topCustomers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text('No customer data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: _topCustomers.map((customer) {
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              title: Text(customer['name'] ?? 'Unknown'),
              subtitle: Text('${customer['invoice_count'] ?? 0} invoices'),
              trailing: Text(
                '₹${(customer['total_amount'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Helper widgets moved outside of the state class
class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: AppConstants.iconSizeMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppTheme.accentColor : AppTheme.errorColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      color: isPositive ? AppTheme.accentColor : AppTheme.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall / 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSalesItem extends StatelessWidget {
  final String name;
  final String amount;
  final int percentage;

  const _ProductSalesItem(this.name, this.amount, this.percentage);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSalesItem extends StatelessWidget {
  final String name;
  final String amount;
  final int invoices;

  const _CustomerSalesItem(this.name, this.amount, this.invoices);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Text(
            '$invoices invoices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _PaymentStatusRow(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
