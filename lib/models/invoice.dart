import 'product.dart';

class InvoiceItem {
  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    String? id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalPrice => quantity * unitPrice;

  // Convert from Supabase data
  factory InvoiceItem.fromSupabase(Map<String, dynamic> data) {
    return InvoiceItem(
      id: data['id'],
      product: Product.fromSupabase(data['products']),
      quantity: data['quantity'],
      unitPrice: (data['unit_price'] as num).toDouble(),
    );
  }

  // Convert to Supabase data
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'product_id': product.id,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
    );
  }
}

enum InvoiceStatus { draft, pending, paid, unpaid, overdue }

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  String get dbValue {
    switch (this) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.pending:
        return 'pending';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.unpaid:
        return 'unpaid';
      case InvoiceStatus.overdue:
        return 'overdue';
    }
  }

  static InvoiceStatus fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'pending':
        return InvoiceStatus.pending;
      case 'paid':
        return InvoiceStatus.paid;
      case 'unpaid':
        return InvoiceStatus.unpaid;
      case 'overdue':
        return InvoiceStatus.overdue;
      default:
        return InvoiceStatus.unpaid;
    }
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final DateTime date;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double taxPercentage;
  final InvoiceStatus status;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  Invoice({
    String? id,
    String? invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    DateTime? dueDate,
    required this.items,
    this.taxPercentage = 18.0,
    this.status = InvoiceStatus.unpaid,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
  }) : id = id ?? '',
       invoiceNumber = invoiceNumber ?? _generateInvoiceNumber(),
       dueDate = dueDate ?? date.add(const Duration(days: 30)),
       subtotal = subtotal ?? _calculateSubtotal(items),
       taxAmount = taxAmount ?? _calculateTaxAmount(subtotal ?? _calculateSubtotal(items), taxPercentage),
       totalAmount = totalAmount ?? _calculateTotal(subtotal ?? _calculateSubtotal(items), taxAmount ?? _calculateTaxAmount(subtotal ?? _calculateSubtotal(items), taxPercentage));

  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  static double _calculateSubtotal(List<InvoiceItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  static double _calculateTaxAmount(double subtotal, double taxPercentage) {
    return subtotal * (taxPercentage / 100);
  }

  static double _calculateTotal(double subtotal, double taxAmount) {
    return subtotal + taxAmount;
  }

  // Legacy compatibility getters
  double get total => totalAmount;

  String get statusText {
    return status.displayName;
  }

  // Convert from Supabase data
  factory Invoice.fromSupabase(Map<String, dynamic> data) {
    final invoiceItems = (data['invoice_items'] as List? ?? [])
        .map((item) => InvoiceItem.fromSupabase(item))
        .toList();

    return Invoice(
      id: data['id'],
      invoiceNumber: data['invoice_number'],
      customerId: data['customer_id'],
      customerName: data['customers']['name'],
      date: DateTime.parse(data['date']),
      dueDate: DateTime.parse(data['due_date']),
      items: invoiceItems,
      taxPercentage: (data['tax_percentage'] as num).toDouble(),
      status: InvoiceStatusExtension.fromDbValue(data['status']),
      subtotal: (data['subtotal'] as num).toDouble(),
      taxAmount: (data['tax_amount'] as num).toDouble(),
      totalAmount: (data['total_amount'] as num).toDouble(),
    );
  }

  // Convert to Supabase data
  Map<String, dynamic> toSupabase() {
    final data = {
      'customer_id': customerId,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'tax_percentage': taxPercentage,
      'status': status.dbValue,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
    };
    // Don't send invoice_number or id - let database generate them
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'taxPercentage': taxPercentage,
      'status': status.index,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      date: DateTime.parse(json['date']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      taxPercentage: json['taxPercentage']?.toDouble() ?? 18.0,
      status: InvoiceStatus.values[json['status'] ?? 1],
      subtotal: json['subtotal']?.toDouble(),
      taxAmount: json['taxAmount']?.toDouble(),
      totalAmount: json['totalAmount']?.toDouble(),
    );
  }
}
