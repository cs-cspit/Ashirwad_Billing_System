import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer; // For editing existing customer
  
  const AddCustomerScreen({
    super.key,
    this.customer,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _contactController.text = widget.customer!.contactNumber;
      _gstController.text = widget.customer!.gstNumber ?? '';
      _addressController.text = widget.customer!.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter customer name';
    }
    if (value.trim().length < 2) {
      return 'Customer name must be at least 2 characters';
    }
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter contact number';
    }
    // Remove spaces and special characters for validation
    String cleanNumber = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.length < 10) {
      return 'Please enter a valid contact number';
    }
    return null;
  }

  String? _validateGST(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter GST number';
    }
    // Basic GST validation (15 characters)
    if (value.trim().length != 15) {
      return 'GST number must be 15 characters';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter address';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
      );

      if (widget.customer != null) {
        await SupabaseService.updateCustomer(customer);
      } else {
        await SupabaseService.addCustomer(customer);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer != null 
                ? 'Customer updated successfully!' 
                : 'Customer added successfully!',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        Navigator.pop(context, customer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: Show delete confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Customer'),
                    content: const Text('Are you sure you want to delete this customer?'),
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
                              content: Text('Customer deleted successfully!'),
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
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      CustomTextField(
                        label: 'Customer Name',
                        hint: 'Enter customer/company name',
                        controller: _nameController,
                        prefixIcon: Icons.business,
                        validator: _validateName,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      CustomTextField(
                        label: 'Contact Number',
                        hint: '+91 9876543210',
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone,
                        validator: _validateContact,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Business Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      CustomTextField(
                        label: 'GST Number',
                        hint: 'Enter 15-digit GST number',
                        controller: _gstController,
                        prefixIcon: Icons.receipt_long,
                        validator: _validateGST,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      CustomTextField(
                        label: 'Address',
                        hint: 'Enter complete business address',
                        controller: _addressController,
                        prefixIcon: Icons.location_on,
                        maxLines: 3,
                        validator: _validateAddress,
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
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  _nameController.text.isNotEmpty 
                                    ? _nameController.text[0].toUpperCase() 
                                    : 'C',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
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
                                        : 'Customer Name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (_contactController.text.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _contactController.text,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    if (_gstController.text.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'GST: ${_gstController.text.toUpperCase()}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
                      const Text('• Use official company/business name'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Verify GST number for accuracy'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Include complete address with pincode'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Use primary contact number'),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      const Text('• Double-check all information before saving'),
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
          text: isEditing ? 'Update Customer' : 'Add Customer',
          icon: isEditing ? Icons.update : Icons.person_add,
          onPressed: _saveCustomer,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
