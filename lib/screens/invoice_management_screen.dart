import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/invoice.dart';
import '../services/supabase_service.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;
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

  List<String> get _statusOptions {
    return ['All', 'Draft', 'Pending', 'Paid', 'Overdue'];
  }

  void _filterInvoices() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        bool matchesSearch = invoice.id.toLowerCase().contains(searchQuery) ||
            invoice.customerName.toLowerCase().contains(searchQuery);
        
        bool matchesStatus = _selectedStatus == 'All' || 
            invoice.status.toString().split('.').last.toLowerCase() == _selectedStatus.toLowerCase();
        
        bool matchesDate = _selectedDateRange == null ||
            (invoice.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             invoice.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        
        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
    });
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _filterInvoices();
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
    _filterInvoices();
  }

  void _createNewInvoice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateInvoiceScreen(),
      ),
    );

    if (result != null && result is Invoice) {
      try {
        final newInvoice = await SupabaseService.createInvoice(result);
        setState(() {
          _allInvoices.insert(0, newInvoice);
          _filterInvoices();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create invoice: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewInvoiceDetails(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }

  void _editInvoice(Invoice invoice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );

    if (result != null) {
      _loadInvoices(); // Reload invoices after editing
    }
  }

  void _duplicateInvoice(Invoice invoice) async {
    final newInvoice = Invoice(
      id: '', // The ID will be generated by Supabase
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      items: invoice.items,
      status: InvoiceStatus.draft,
      subtotal: invoice.subtotal,
      taxAmount: invoice.taxAmount,
      totalAmount: invoice.totalAmount,
    );

    try {
      final createdInvoice = await SupabaseService.createInvoice(newInvoice);
      setState(() {
        _allInvoices.insert(0, createdInvoice);
        _filterInvoices();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${invoice.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await SupabaseService.deleteInvoice(invoice.id);
                setState(() {
                  _allInvoices.removeWhere((i) => i.id == invoice.id);
                  _filterInvoices();
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice ${invoice.id} deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete invoice: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return AppTheme.warningColor;
      case InvoiceStatus.paid:
        return AppTheme.successColor;
      case InvoiceStatus.unpaid:
        return AppTheme.warningColor;
      case InvoiceStatus.overdue:
        return AppTheme.errorColor;
    }
  }

  String _getStatusText(InvoiceStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _allInvoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final paidAmount = _allInvoices
        .where((i) => i.status == InvoiceStatus.paid)
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final pendingAmount = _allInvoices
        .where((i) => i.status == InvoiceStatus.pending || i.status == InvoiceStatus.overdue)
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewInvoice,
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
                CustomTextField(
                  label: 'Search Invoices',
                  hint: 'Search by invoice ID or customer name',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onTap: () {},
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _filterInvoices();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _selectDateRange,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange == null
                                          ? 'Select Date Range'
                                          : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                                      style: TextStyle(
                                        color: _selectedDateRange == null
                                            ? Colors.grey[600]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_selectedDateRange != null)
                                    GestureDetector(
                                      onTap: _clearDateRange,
                                      child: const Icon(Icons.clear, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Cards
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹${(totalAmount / 100000).toStringAsFixed(1)}L',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Text('Total Revenue'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹${(paidAmount / 100000).toStringAsFixed(1)}L',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const Text('Paid'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹${(pendingAmount / 100000).toStringAsFixed(1)}L',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const Text('Pending'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Invoice List
          Expanded(
            child: _filteredInvoices.isEmpty
                ? EmptyStateWidget(
                    message: _searchController.text.isNotEmpty || _selectedStatus != 'All' || _selectedDateRange != null
                        ? 'No invoices found matching your filters'
                        : 'No invoices created yet',
                    icon: Icons.receipt_long,
                    actionText: 'Create Invoice',
                    onAction: _createNewInvoice,
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
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: _getStatusColor(invoice.status),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                invoice.id,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusText(invoice.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getStatusColor(invoice.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(invoice.customerName),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Text(' • '),
                                  Text(
                                    'Due: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: invoice.status == InvoiceStatus.overdue
                                          ? AppTheme.errorColor
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _viewInvoiceDetails(invoice);
                                      break;
                                    case 'edit':
                                      _editInvoice(invoice);
                                      break;
                                    case 'duplicate':
                                      _duplicateInvoice(invoice);
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
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy),
                                        SizedBox(width: 8),
                                        Text('Duplicate'),
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
                          onTap: () => _viewInvoiceDetails(invoice),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_invoice',
        onPressed: _createNewInvoice,
        child: const Icon(Icons.add),
      ),
    );
  }
}
