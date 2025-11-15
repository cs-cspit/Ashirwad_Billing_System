import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/invoice.dart';
import '../services/supabase_service.dart';
import '../utils/pdf_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice; // Initialize immediately to avoid late initialization error
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final invoice = await SupabaseService.getInvoiceById(widget.invoice.id);

      setState(() {
        _invoice = invoice;
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
            content: Text('Failed to load invoice: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadInvoice,
            ),
          ),
        );
      }
    }
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

  void _markAsPaid() async {
    if (_invoice.status != InvoiceStatus.paid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedInvoice = Invoice(
          id: _invoice.id,
          invoiceNumber: _invoice.invoiceNumber,
          customerId: _invoice.customerId,
          customerName: _invoice.customerName,
          date: _invoice.date,
          dueDate: _invoice.dueDate,
          items: _invoice.items,
          status: InvoiceStatus.paid,
          subtotal: _invoice.subtotal,
          taxAmount: _invoice.taxAmount,
          taxPercentage: _invoice.taxPercentage,
          totalAmount: _invoice.totalAmount,
        );

        await SupabaseService.updateInvoice(updatedInvoice);

        setState(() {
          _invoice = updatedInvoice;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice marked as paid'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as paid: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _downloadPDF() async {
    try {
      await PDFService.generateInvoicePDF(_invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markAsUnpaid() async {
    if (_invoice.status == InvoiceStatus.paid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedInvoice = Invoice(
          id: _invoice.id,
          invoiceNumber: _invoice.invoiceNumber,
          customerId: _invoice.customerId,
          customerName: _invoice.customerName,
          date: _invoice.date,
          dueDate: _invoice.dueDate,
          items: _invoice.items,
          status: InvoiceStatus.unpaid,
          subtotal: _invoice.subtotal,
          taxAmount: _invoice.taxAmount,
          taxPercentage: _invoice.taxPercentage,
          totalAmount: _invoice.totalAmount,
        );

        await SupabaseService.updateInvoice(updatedInvoice);

        setState(() {
          _invoice = updatedInvoice;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice marked as unpaid'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as unpaid: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _shareInvoice() async {
    try {
      await PDFService.generateInvoicePDF(_invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated! Share functionality coming soon.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${_invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                await PDFService.generateInvoicePDF(_invoice);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF downloaded successfully!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating PDF: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'download':
                  PDFService.generateInvoicePDF(_invoice);
                  break;
                case 'paid':
                  _markAsPaid();
                  break;
                case 'unpaid':
                  _markAsUnpaid();
                  break;
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Invoice'),
                      content: Text('Are you sure you want to delete invoice ${_invoice.invoiceNumber}?'),
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
                      await SupabaseService.deleteInvoice(_invoice.id);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice deleted successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete invoice: $e')),
                        );
                      }
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              if (_invoice.status != InvoiceStatus.paid)
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
              if (_invoice.status == InvoiceStatus.paid)
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
                        'Failed to load invoice',
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
                        onPressed: _loadInvoice,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _invoice.invoiceNumber,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              'Date: ${_formatDate(_invoice.date)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_invoice.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                          ),
                          child: Text(
                            _invoice.status.toString().split('.').last,
                            style: TextStyle(
                              color: _getStatusColor(_invoice.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Customer Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _InfoRow(
                      label: 'Customer Name',
                      value: _invoice.customerName,
                    ),
                    _InfoRow(
                      label: 'Customer ID',
                      value: _invoice.customerId,
                    ),
                    // TODO: Add more customer details when customer model is linked
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Invoice Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    if (_invoice.items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppConstants.paddingLarge),
                          child: Text('No items in this invoice'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoice.items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _invoice.items[index];
                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Text('Qty: ${item.quantity}'),
                              ),
                              Expanded(
                                child: Text('₹${item.unitPrice.toStringAsFixed(2)}'),
                              ),
                              Expanded(
                                child: Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
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

            const SizedBox(height: AppConstants.paddingMedium),

            // Invoice Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '₹${_invoice.subtotal.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'Tax (${_invoice.taxPercentage}%)',
                      value: '₹${_invoice.taxAmount.toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _SummaryRow(
                      label: 'Total',
                      value: '₹${_invoice.totalAmount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Download PDF',
                    icon: Icons.download,
                    onPressed: _downloadPDF,
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: CustomButton(
                    text: 'Share',
                    icon: Icons.share,
                    onPressed: _shareInvoice,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (_invoice.status != InvoiceStatus.paid)
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Mark as Paid',
                  icon: Icons.check,
                  onPressed: _markAsPaid,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
