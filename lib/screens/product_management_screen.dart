import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import 'add_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await SupabaseService.getProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
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
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    }
  }

  List<String> get _categories {
    final categories = _allProducts.map((p) => p.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  void _filterProducts() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        bool matchesSearch = product.name.toLowerCase().contains(searchQuery) ||
            product.description.toLowerCase().contains(searchQuery) ||
            product.category.toLowerCase().contains(searchQuery);
        bool matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addNewProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (result != null && result is Product) {
      try {
        final addedProduct = await SupabaseService.addProduct(result);
        setState(() {
          _allProducts.add(addedProduct);
          _filterProducts();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );

    if (result != null && result is Product) {
      try {
        final updatedProduct = await SupabaseService.updateProduct(result);
        setState(() {
          int index = _allProducts.indexWhere((p) => p.id == product.id);
          if (index != -1) {
            _allProducts[index] = updatedProduct;
            _filterProducts();
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await SupabaseService.deleteProduct(product.id);
                setState(() {
                  _allProducts.removeWhere((p) => p.id == product.id);
                  _filterProducts();
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete product: $e'),
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

  void _viewProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ProductDetailsSheet(
        product: product,
        onEdit: () {
          Navigator.pop(context);
          _editProduct(product);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteProduct(product);
        },
      ),
    );
  }

  Color _getStockStatusColor(Product product) {
    if (product.stockQuantity <= product.minStockLevel) {
      return AppTheme.errorColor;
    } else if (product.stockQuantity <= product.minStockLevel * 2) {
      return AppTheme.warningColor;
    }
    return AppTheme.successColor;
  }

  String _getStockStatus(Product product) {
    if (product.stockQuantity <= product.minStockLevel) {
      return 'Low Stock';
    } else if (product.stockQuantity <= product.minStockLevel * 2) {
      return 'Medium Stock';
    }
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = _allProducts.where((p) => p.stockQuantity <= p.minStockLevel).length;
    final totalValue = _allProducts.fold(0.0, (sum, p) => sum + (p.price * p.stockQuantity));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Search Products',
                  hint: 'Search by name, description, or category',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onTap: () {},
                  onChanged: (value) => _filterProducts(),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                      _filterProducts();
                    });
                  },
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
                            '${_allProducts.length}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const Text('Total Products'),
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
                            '$lowStockProducts',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const Text('Low Stock'),
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
                            '₹${(totalValue / 100000).toStringAsFixed(1)}L',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const Text('Total Value'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? EmptyStateWidget(
                    message: _searchController.text.isNotEmpty || _selectedCategory != 'All'
                        ? 'No products found matching your search'
                        : 'No products added yet',
                    icon: Icons.inventory_2_outlined,
                    actionText: 'Add Product',
                    onAction: _addNewProduct,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.category,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '₹${product.price.toStringAsFixed(2)}/${product.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStockStatusColor(product).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStockStatus(product),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _getStockStatusColor(product),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${product.stockQuantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _viewProductDetails(product);
                                        break;
                                      case 'edit':
                                        _editProduct(product);
                                        break;
                                      case 'delete':
                                        _deleteProduct(product);
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
                          ),
                          onTap: () => _viewProductDetails(product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_product',
        onPressed: _addNewProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductDetailsSheet({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Product ID: ${product.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          _DetailRow(
            icon: Icons.category,
            label: 'Category',
            value: product.category,
          ),

          _DetailRow(
            icon: Icons.description,
            label: 'Description',
            value: product.description,
          ),

          _DetailRow(
            icon: Icons.currency_rupee,
            label: 'Price',
            value: '₹${product.price.toStringAsFixed(2)} per ${product.unit}',
          ),

          _DetailRow(
            icon: Icons.inventory,
            label: 'Stock Quantity',
            value: '${product.stockQuantity} ${product.unit}',
          ),

          _DetailRow(
            icon: Icons.warning,
            label: 'Minimum Stock Level',
            value: '${product.minStockLevel} ${product.unit}',
          ),

          _DetailRow(
            icon: Icons.calculate,
            label: 'Total Value',
            value: '₹${(product.price * product.stockQuantity).toStringAsFixed(2)}',
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Product',
                  icon: Icons.edit,
                  onPressed: onEdit,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: CustomButton(
                  text: 'Delete',
                  icon: Icons.delete,
                  onPressed: onDelete,
                  isSecondary: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Update Stock',
              icon: Icons.add_box,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stock update functionality coming soon'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
