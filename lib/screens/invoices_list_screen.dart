import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/invoice.dart';
import '../services/supabase_service.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final invoices = await SupabaseService.getInvoices();
      setState(() {
        _allInvoices = invoices;
        _filteredInvoices = invoices;
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
            content: Text('Failed to load invoices: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadInvoices,
            ),
          ),
        );
      }
    }
  }

  void _filterInvoices() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        bool matchesSearch = invoice.invoiceNumber.toLowerCase().contains(searchQuery) ||
            invoice.customerName.toLowerCase().contains(searchQuery);

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Paid' && invoice.status == InvoiceStatus.paid) ||
            (_selectedFilter == 'Unpaid' && invoice.status == InvoiceStatus.unpaid) ||
            (_selectedFilter == 'Overdue' && invoice.status == InvoiceStatus.overdue);

        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null) {
          matchesDateRange = invoice.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                              invoice.date.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesFilter && matchesDateRange;
      }).toList();
    });
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return AppTheme.warningColor;
      case InvoiceStatus.paid:
        return AppTheme.accentColor;
      case InvoiceStatus.unpaid:
        return AppTheme.warningColor;
      case InvoiceStatus.overdue:
        return AppTheme.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteInvoice(invoice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
          _loadInvoices();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete invoice: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAsPaid(Invoice invoice) async {
    try {
      final updatedInvoice = Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        date: invoice.date,
        dueDate: invoice.dueDate,
        items: invoice.items,
        taxPercentage: invoice.taxPercentage,
        status: InvoiceStatus.paid,
        subtotal: invoice.subtotal,
        taxAmount: invoice.taxAmount,
        totalAmount: invoice.totalAmount,
      );
      
      await SupabaseService.updateInvoice(updatedInvoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as paid')),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update invoice: $e')),
        );
      }
    }
  }

  Future<void> _markAsUnpaid(Invoice invoice) async {
    try {
      final updatedInvoice = Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        date: invoice.date,
        dueDate: invoice.dueDate,
        items: invoice.items,
        taxPercentage: invoice.taxPercentage,
        status: InvoiceStatus.unpaid,
        subtotal: invoice.subtotal,
        taxAmount: invoice.taxAmount,
        totalAmount: invoice.totalAmount,
      );

      await SupabaseService.updateInvoice(updatedInvoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as unpaid')),
        );
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInvoiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load invoices',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInvoices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Search Bar
                CustomTextField(
                  label: 'Search Invoices',
                  hint: 'Enter invoice number or customer name',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onTap: () {},
                  onChanged: (value) => _filterInvoices(),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Filter Chips and Date Filter
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Paid', 'Unpaid', 'Overdue'].map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                              child: FilterChip(
                                label: Text(filter),
                                selected: _selectedFilter == filter,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                    _filterInvoices();
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.date_range,
                        color: _startDate != null ? AppTheme.primaryColor : null,
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: _startDate != null && _endDate != null
                              ? DateTimeRange(start: _startDate!, end: _endDate!)
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                            _filterInvoices();
                          });
                        }
                      },
                      tooltip: 'Filter by date range',
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _filterInvoices();
                          });
                        },
                        tooltip: 'Clear date filter',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: _filteredInvoices.isEmpty
                ? EmptyStateWidget(
                    message: _searchController.text.isNotEmpty || _selectedFilter != 'All'
                        ? 'No invoices found matching your criteria'
                        : 'No invoices created yet',
                    icon: Icons.receipt_long_outlined,
                    actionText: 'Create Invoice',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateInvoiceScreen(),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    itemCount: _filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _filteredInvoices[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(invoice.status).withOpacity(0.1),
                            child: Icon(
                              Icons.receipt,
                              color: _getStatusColor(invoice.status),
                            ),
                          ),
                          title: Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(invoice.customerName),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(invoice.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      invoice.status.toString().split('.').last,
                                      style: TextStyle(
                                        color: _getStatusColor(invoice.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'view':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InvoiceDetailScreen(invoice: invoice),
                                        ),
                                      );
                                      break;
                                    case 'paid':
                                      _markAsPaid(invoice);
                                      break;
                                    case 'unpaid':
                                      _markAsUnpaid(invoice);
                                      break;
                                    case 'delete':
                                      _deleteInvoice(invoice);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View'),
                                      ],
                                    ),
                                  ),
                                  if (invoice.status != InvoiceStatus.paid)
                                    const PopupMenuItem(
                                      value: 'paid',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Mark as Paid'),
                                        ],
                                      ),
                                    ),
                                  if (invoice.status == InvoiceStatus.paid)
                                    const PopupMenuItem(
                                      value: 'unpaid',
                                      child: Row(
                                        children: [
                                          Icon(Icons.money_off, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Mark as Unpaid'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailScreen(invoice: invoice),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_invoice_list',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
