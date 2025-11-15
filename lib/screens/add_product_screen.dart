import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // For editing existing product
  
  const AddProductScreen({
    super.key,
    this.product,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  
  String _selectedUnit = 'Kg';
  String _selectedCategory = 'PP Granules';
  bool _isLoading = false;

  final List<String> _units = ['Kg', 'Ton', 'Piece', 'Box', 'Bag'];
  final List<String> _categories = [
    'PP Granules',
    'HDPE Granules',
    'LDPE Granules',
    'PVC Granules',
    'ABS Granules',
    'PS Granules',
    'PC Granules',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.stockQuantity.toString();
      _minStockController.text = widget.product!.minStockLevel.toString();
      _selectedUnit = widget.product!.unit;
      _selectedCategory = widget.product!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter product name';
    }
    if (value.trim().length < 2) {
      return 'Product name must be at least 2 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter product description';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter price per unit';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Please enter a valid price';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter stock quantity';
    }
    final quantity = int.tryParse(value);
    if (quantity == null || quantity < 0) {
      return 'Please enter a valid quantity';
    }
    return null;
  }

  String? _validateMinStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter minimum stock level';
    }
    final minStock = int.tryParse(value);
    if (minStock == null || minStock < 0) {
      return 'Please enter a valid minimum stock level';
    }
    return null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        unit: _selectedUnit,
        category: _selectedCategory,
        stockQuantity: int.parse(_quantityController.text),
        minStockLevel: int.parse(_minStockController.text),
      );

      if (widget.product != null) {
        await SupabaseService.updateProduct(product);
      } else {
        await SupabaseService.addProduct(product);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null 
                ? 'Product updated successfully!' 
                : 'Product added successfully!',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        Navigator.pop(context, product);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: Show delete confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted successfully!'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      CustomTextField(
                        label: 'Product Name',
                        hint: 'Enter product name (e.g., PP Granules)',
                        controller: _nameController,
                        prefixIcon: Icons.inventory_2,
                        validator: _validateName,
                        onTap: () {},
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      CustomTextField(
                        label: 'Description',
                        hint: 'Enter detailed product description',
                        controller: _descriptionController,
                        maxLines: 3,
                        prefixIcon: Icons.description,
                        validator: _validateDescription,
                        onTap: () {},
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
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
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Price per Unit (₹)',
                              hint: 'Enter price',
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.currency_rupee,
                              validator: _validatePrice,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a unit';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Stock Quantity',
                              hint: 'Enter current stock',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.inventory,
                              validator: _validateQuantity,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            child: CustomTextField(
                              label: 'Min Stock Level',
                              hint: 'Enter minimum stock',
                              controller: _minStockController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.warning,
                              validator: _validateMinStock,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Preview Card
              if (_nameController.text.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        Container(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: AppTheme.primaryColor,
                                  size: AppConstants.iconSizeLarge,
                                ),
                              ),
                              const SizedBox(width: AppConstants.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameController.text.isNotEmpty 
                                        ? _nameController.text 
                                        : 'Product Name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: AppConstants.paddingSmall / 2),
                                    Text(
                                      '₹${_priceController.text.isNotEmpty ? _priceController.text : '0.00'} per unit',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_quantityController.text.isNotEmpty ? _quantityController.text : '0'} units available',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Guidelines Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Text(
                            'Guidelines',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      const Text('• Use clear, descriptive product names'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Include grade/quality in name (e.g., Virgin, Recycled)'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Keep pricing competitive and up-to-date'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Update quantity regularly to avoid stock-outs'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: CustomButton(
          text: isEditing ? 'Update Product' : 'Add Product',
          icon: isEditing ? Icons.update : Icons.add,
          onPressed: _saveProduct,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
