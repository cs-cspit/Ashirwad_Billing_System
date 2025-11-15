import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Authentication
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await _client
          .from('users')
          .select('id, password_hash')
          .eq('email', email)
          .single();

      final user = response;
      final passwordHash = user['password_hash'] as String;

      if (BCrypt.checkpw(password, passwordHash)) {
        return user;
      } else {
        throw Exception('Invalid password');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  static Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final response = await _client
          .from('users')
          .insert({'email': email, 'password_hash': passwordHash})
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Customer Operations
  static Future<List<Customer>> getCustomers() async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Customer.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  static Future<Customer> addCustomer(Customer customer) async {
    try {
      final response = await _client
          .from('customers')
          .insert(customer.toSupabase())
          .select()
          .single();
      
      return Customer.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  static Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response = await _client
          .from('customers')
          .update(customer.toSupabase())
          .eq('id', customer.id)
          .select()
          .single();
      
      return Customer.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  static Future<void> deleteCustomer(String customerId) async {
    try {
      await _client
          .from('customers')
          .delete()
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // Product Operations
  static Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Product.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  static Future<Product> addProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product.toSupabase())
          .select()
          .single();
      
      return Product.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  static Future<Product> updateProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .update(product.toSupabase())
          .eq('id', product.id)
          .select()
          .single();
      
      return Product.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .delete()
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Invoice Operations
  static Future<List<Invoice>> getInvoices() async {
    try {
      final response = await _client
          .from('invoices')
          .select('''
            *,
            customers!inner(name),
            invoice_items(
              *,
              products(*)
            )
          ''')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Invoice.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  static Future<Invoice> getInvoiceById(String invoiceId) async {
    try {
      final response = await _client
          .from('invoices')
          .select('''
            *,
            customers!inner(name),
            invoice_items(
              *,
              products(*)
            )
          ''')
          .eq('id', invoiceId)
          .single();
      
      return Invoice.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  static Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      // Prepare invoice data without ID and invoice_number (auto-generated by DB)
      final invoiceData = {
        'customer_id': invoice.customerId,
        'date': invoice.date.toIso8601String().split('T')[0],
        'due_date': invoice.dueDate.toIso8601String().split('T')[0],
        'status': invoice.status.name,
        'subtotal': invoice.subtotal,
        'tax_amount': invoice.taxAmount,
        'total_amount': invoice.totalAmount,
      };
      
      final invoiceResponse = await _client
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();
      
      final invoiceId = invoiceResponse['id'];
      
      // Insert invoice items
      if (invoice.items.isNotEmpty) {
        final itemsData = invoice.items.map((item) => {
          'invoice_id': invoiceId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        }).toList();
        
        await _client
            .from('invoice_items')
            .insert(itemsData);
      }
      
      // Fetch the complete invoice with customer name
      final completeInvoice = await _client
          .from('invoices')
          .select('''
            *,
            customers!inner(name)
          ''')
          .eq('id', invoiceId)
          .single();
      
      return Invoice.fromSupabase(completeInvoice);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  static Future<Invoice> updateInvoice(Invoice invoice) async {
    try {
      // Update invoice
      final invoiceData = invoice.toSupabase();
      invoiceData.remove('invoice_items'); // Remove items for separate handling
      
      await _client
          .from('invoices')
          .update(invoiceData)
          .eq('id', invoice.id);
      
      // Delete existing items and insert new ones
      await _client
          .from('invoice_items')
          .delete()
          .eq('invoice_id', invoice.id);
      
      if (invoice.items.isNotEmpty) {
        final itemsData = invoice.items.map((item) {
          final itemData = item.toSupabase();
          itemData['invoice_id'] = invoice.id;
          return itemData;
        }).toList();
        
        await _client
            .from('invoice_items')
            .insert(itemsData);
      }
      
      // Fetch the updated invoice
      return await getInvoiceById(invoice.id);
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _client
          .from('invoices')
          .delete()
          .eq('id', invoiceId);
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  // Tax Settings Operations
  static Future<Map<String, dynamic>> getTaxSettings() async {
    try {
      final response = await _client
          .from('tax_settings')
          .select()
          .eq('is_active', true)
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to fetch tax settings: $e');
    }
  }

  static Future<void> updateTaxSettings(Map<String, dynamic> settings) async {
    try {
      // Deactivate all existing settings
      await _client
          .from('tax_settings')
          .update({'is_active': false})
          .eq('is_active', true);
      
      // Insert new settings
      await _client
          .from('tax_settings')
          .insert({
            ...settings,
            'is_active': true,
          });
    } catch (e) {
      throw Exception('Failed to update tax settings: $e');
    }
  }

  // Dashboard/Analytics
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get customer count
      final customersResponse = await _client
          .from('customers')
          .select('id');
      final customerCount = (customersResponse as List).length;

      // Get product count
      final productsResponse = await _client
          .from('products')
          .select('id');
      final productCount = (productsResponse as List).length;

      // Get invoice count
      final invoicesResponse = await _client
          .from('invoices')
          .select('id');
      final invoiceCount = (invoicesResponse as List).length;

      // Get all invoices with amounts
      final allInvoices = await _client
          .from('invoices')
          .select('total_amount, status, date');

      double totalRevenue = 0;
      double monthRevenue = 0;
      double todayRevenue = 0;
      int pendingInvoices = 0;
      int overdueInvoices = 0;

      for (var invoice in allInvoices) {
        final amount = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;
        final status = invoice['status'] as String?;
        final dateStr = invoice['date'] as String?;
        
        if (status == 'paid') {
          totalRevenue += amount;
          
          if (dateStr != null) {
            final invoiceDate = DateTime.parse(dateStr);
            if (invoiceDate.year == now.year && invoiceDate.month == now.month) {
              monthRevenue += amount;
            }
            if (invoiceDate.year == today.year && 
                invoiceDate.month == today.month && 
                invoiceDate.day == today.day) {
              todayRevenue += amount;
            }
          }
        } else if (status == 'pending' || status == 'unpaid') {
          pendingInvoices++;
        } else if (status == 'overdue') {
          overdueInvoices++;
        }
      }

      // Get recent invoices
      final recentInvoicesData = await _client
          .from('invoices')
          .select('''
            id,
            invoice_number,
            total_amount,
            date,
            customers!inner(name)
          ''')
          .order('created_at', ascending: false)
          .limit(5);

      final recentInvoices = (recentInvoicesData as List).map((inv) => {
        'invoiceNumber': inv['invoice_number'],
        'customerName': inv['customers']['name'],
        'invoiceDate': inv['date'],
        'totalAmount': inv['total_amount'],
      }).toList();

      // Get top products (mock data for now)
      final topProducts = <Map<String, dynamic>>[];

      return {
        'totalCustomers': customerCount,
        'totalProducts': productCount,
        'totalInvoices': invoiceCount,
        'totalRevenue': totalRevenue,
        'monthRevenue': monthRevenue,
        'todayRevenue': todayRevenue,
        'pendingInvoices': pendingInvoices,
        'overdueInvoices': overdueInvoices,
        'recentInvoices': recentInvoices,
        'topProducts': topProducts,
      };
    } catch (e) {
      print('Dashboard error: $e');
      // Return default values on error
      return {
        'totalCustomers': 0,
        'totalProducts': 0,
        'totalInvoices': 0,
        'totalRevenue': 0.0,
        'monthRevenue': 0.0,
        'todayRevenue': 0.0,
        'pendingInvoices': 0,
        'overdueInvoices': 0,
        'recentInvoices': <Map<String, dynamic>>[],
        'topProducts': <Map<String, dynamic>>[],
      };
    }
  }

  static Future<Map<String, dynamic>> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    try {
      var query = _client.from('invoices').select('total_amount, status');

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }
      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query;
      final List<Map<String, dynamic>> invoices = (response as List).cast<Map<String, dynamic>>();

      double totalRevenue = 0;
      double pendingAmount = 0;
      double collectedAmount = 0;
      int totalInvoices = invoices.length;

      for (var invoice in invoices) {
        final amount = (invoice['total_amount'] as num).toDouble();
        final status = invoice['status'] as String;

        if (status == 'paid') {
          totalRevenue += amount;
          collectedAmount += amount;
        } else if (status == 'pending' || status == 'unpaid' || status == 'overdue') {
          pendingAmount += amount;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalInvoices': totalInvoices,
        'pendingAmount': pendingAmount,
        'collectedAmount': collectedAmount,
      };
    } catch (e) {
      throw Exception('Failed to fetch report summary: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTopProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    try {
      var queryBuilder = _client
          .from('invoice_items')
          .select('quantity, unit_price, products(name), invoices(customer_id)');

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String().split('T')[0]);
      }
      if (customerId != null && customerId.isNotEmpty) {
        // filter invoice_items by related invoice's customer_id
        queryBuilder = queryBuilder.eq('invoices.customer_id', customerId);
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      final List<Map<String, dynamic>> items = (response as List).cast<Map<String, dynamic>>();

      final Map<String, int> productQty = {};
      final Map<String, double> productRevenue = {};
      for (var item in items) {
        final productName = (item['products'] as Map<String, dynamic>)['name'] as String;
        final quantity = (item['quantity'] as num).toInt();
        final unitPrice = (item['unit_price'] as num).toDouble();
        productQty.update(productName, (v) => v + quantity, ifAbsent: () => quantity);
        productRevenue.update(productName, (v) => v + (quantity * unitPrice), ifAbsent: () => (quantity * unitPrice));
      }

      final entries = productRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return entries.take(limit).map((e) {
        final name = e.key;
        return {
          'name': name,
          'total_quantity': productQty[name] ?? 0,
          'total_revenue': e.value,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch top products: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTopCustomers({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    try {
      var queryBuilder = _client
          .from('invoices')
          .select('total_amount, customers(name)');

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        queryBuilder = queryBuilder.lte('date', endDate.toIso8601String().split('T')[0]);
      }
      if (customerId != null && customerId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('customer_id', customerId);
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      final List<Map<String, dynamic>> invoices = (response as List).cast<Map<String, dynamic>>();

      final Map<String, Map<String, dynamic>> customerStats = {};
      for (var invoice in invoices) {
        final customerName = (invoice['customers'] as Map<String, dynamic>)['name'] as String;
        final totalAmount = (invoice['total_amount'] as num).toDouble();

        customerStats.update(customerName, (value) {
          value['total_amount'] += totalAmount;
          value['invoice_count'] += 1;
          return value;
        }, ifAbsent: () => {'name': customerName, 'total_amount': totalAmount, 'invoice_count': 1});
      }

      final sortedCustomers = customerStats.entries.toList()
        ..sort((a, b) => (b.value['total_amount'] as double).compareTo(a.value['total_amount'] as double));

      return sortedCustomers.take(limit).map((e) => e.value).toList();
    } catch (e) {
      throw Exception('Failed to fetch top customers: $e');
    }
  }

  static Future<Map<String, int>> getInvoiceStatusCounts({
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    try {
      var query = _client.from('invoices').select('status');

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }
      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      final response = await query;
      final List<Map<String, dynamic>> invoices = (response as List).cast<Map<String, dynamic>>();

      int paidCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;

      for (var invoice in invoices) {
        final status = invoice['status'] as String;
        if (status == 'paid') {
          paidCount++;
        } else if (status == 'pending' || status == 'unpaid') {
          pendingCount++;
        } else if (status == 'overdue') {
          overdueCount++;
        }
      }

      return {
        'paid': paidCount,
        'pending': pendingCount,
        'overdue': overdueCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch invoice status counts: $e');
    }
  }

  // Search Operations
  static Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _client
          .from('customers')
          .select()
          .or('name.ilike.%$query%,contact_number.ilike.%$query%,gst_number.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Customer.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  static Future<List<Product>> searchProducts(String query, {String? category}) async {
    try {
      var queryBuilder = _client
          .from('products')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');
      
      if (category != null && category != 'All') {
        queryBuilder = queryBuilder.eq('category', category);
      }
      
      final response = await queryBuilder.order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Product.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  static Future<List<Invoice>> searchInvoices(String query, {String? status}) async {
    try {
      var queryBuilder = _client
          .from('invoices')
          .select('''
            *,
            customers!inner(name)
          ''')
          .or('invoice_number.ilike.%$query%,customers.name.ilike.%$query%');
      
      if (status != null && status != 'All') {
        queryBuilder = queryBuilder.eq('status', status.toLowerCase());
      }
      
      final response = await queryBuilder.order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => Invoice.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search invoices: $e');
    }
  }
}
