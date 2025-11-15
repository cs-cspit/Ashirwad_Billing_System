import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/supabase_service.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gstRateController = TextEditingController();
  final _igstRateController = TextEditingController();
  final _cessRateController = TextEditingController();
  
  bool _enableGST = true;
  bool _enableIGST = true;
  bool _enableCess = false;
  bool _autoCalculateTax = true;
  
  String _taxDisplayMode = 'Inclusive';
  String _gstNumber = 'GST123456789012345'; // Placeholder for now

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTaxSettings();
  }

  Future<void> _loadTaxSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final settings = await SupabaseService.getTaxSettings();
      setState(() {
        _gstRateController.text = (settings['gst_rate'] as num).toString();
        _igstRateController.text = (settings['igst_rate'] as num).toString();
        _cessRateController.text = (settings['cess_rate'] as num).toString();
        // Assuming is_active implies enabled for now
        _enableGST = true; 
        _enableIGST = true;
        _enableCess = (settings['cess_rate'] as num) > 0;
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
            content: Text('Failed to load tax settings: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadTaxSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _gstRateController.dispose();
    _igstRateController.dispose();
    _cessRateController.dispose();
    super.dispose();
  }

  String? _validateTaxRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter tax rate';
    }
    final rate = double.tryParse(value);
    if (rate == null || rate < 0 || rate > 100) {
      return 'Please enter a valid rate (0-100)';
    }
    return null;
  }

  Future<void> _saveTaxSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final settings = {
        'gst_rate': double.parse(_gstRateController.text),
        'igst_rate': double.parse(_igstRateController.text),
        'cess_rate': _enableCess ? double.parse(_cessRateController.text) : 0.0,
      };
      await SupabaseService.updateTaxSettings(settings);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings saved successfully!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save tax settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tax Settings'),
        content: const Text('This will reset all tax settings to default values. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              try {
                final defaultSettings = {
                  'gst_rate': 18.0,
                  'igst_rate': 18.0,
                  'cess_rate': 0.0,
                };
                await SupabaseService.updateTaxSettings(defaultSettings);
                await _loadTaxSettings(); // Reload to reflect defaults
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tax settings reset to defaults'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reset tax settings: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
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
                        'Failed to load tax settings',
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
                        onPressed: _loadTaxSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company GST Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company GST Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'GST Number',
                        controller: TextEditingController(text: _gstNumber),
                        prefixIcon: Icons.receipt_long,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter GST number';
                          }
                          if (value.trim().length != 15) {
                            return 'GST number must be 15 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                            Expanded(
                              child: Text(
                                'This GST number will appear on all invoices and reports',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Tax Rates Configuration
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Rates Configuration',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // GST Settings
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Goods & Services Tax (GST)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Standard GST rate for intra-state sales',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enableGST,
                            onChanged: (value) {
                              setState(() {
                                _enableGST = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_enableGST) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        CustomTextField(
                          label: 'GST Rate (%)',
                          controller: _gstRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.percent,
                          validator: _validateTaxRate,
                        ),
                      ],

                      const SizedBox(height: AppConstants.paddingLarge),

                      // IGST Settings
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Integrated GST (IGST)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'GST rate for inter-state sales',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enableIGST,
                            onChanged: (value) {
                              setState(() {
                                _enableIGST = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_enableIGST) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        CustomTextField(
                          label: 'IGST Rate (%)',
                          controller: _igstRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.percent,
                          validator: _validateTaxRate,
                        ),
                      ],

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Cess Settings
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cess',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Additional cess on applicable products',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enableCess,
                            onChanged: (value) {
                              setState(() {
                                _enableCess = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_enableCess) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        CustomTextField(
                          label: 'Cess Rate (%)',
                          controller: _cessRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.percent,
                          validator: _validateTaxRate,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Tax Display Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Display Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Auto Calculate Tax
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calculate),
                        title: const Text('Auto Calculate Tax'),
                        subtitle: const Text('Automatically calculate tax on invoice items'),
                        trailing: Switch(
                          value: _autoCalculateTax,
                          onChanged: (value) {
                            setState(() {
                              _autoCalculateTax = value;
                            });
                          },
                        ),
                      ),

                      const Divider(),

                      // Tax Display Mode
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.visibility),
                        title: const Text('Tax Display Mode'),
                        subtitle: Text('Current: $_taxDisplayMode'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showTaxDisplayModeDialog();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Tax Calculation Preview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Calculation Preview',
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
                        child: Column(
                          children: [
                            _TaxPreviewRow('Product Amount', '₹1,000.00'),
                            if (_enableGST)
                              _TaxPreviewRow('GST (${_gstRateController.text}%)', '₹${(1000 * (double.tryParse(_gstRateController.text) ?? 0) / 100).toStringAsFixed(2)}'),
                            if (_enableCess && double.tryParse(_cessRateController.text) != null && double.parse(_cessRateController.text) > 0)
                              _TaxPreviewRow('Cess (${_cessRateController.text}%)', '₹${(1000 * (double.tryParse(_cessRateController.text) ?? 0) / 100).toStringAsFixed(2)}'),
                            const Divider(),
                            _TaxPreviewRow(
                              'Total Amount',
                              '₹${_calculateTotalWithTax(1000).toStringAsFixed(2)}',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: CustomButton(
          text: 'Save Tax Settings',
          icon: Icons.save,
          onPressed: _saveTaxSettings,
        ),
      ),
    );
  }

  void _showTaxDisplayModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Display Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Inclusive',
            'Exclusive',
            'Separate Line Item',
          ].map((mode) {
            return RadioListTile<String>(
              title: Text(mode),
              subtitle: Text(_getTaxDisplayDescription(mode)),
              value: mode,
              groupValue: _taxDisplayMode,
              onChanged: (value) {
                setState(() {
                  _taxDisplayMode = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getTaxDisplayDescription(String mode) {
    switch (mode) {
      case 'Inclusive':
        return 'Tax included in product price';
      case 'Exclusive':
        return 'Tax added to product price';
      case 'Separate Line Item':
        return 'Tax shown as separate line';
      default:
        return '';
    }
  }

  double _calculateTotalWithTax(double amount) {
    double total = amount;
    if (_enableGST) {
      total += amount * (double.tryParse(_gstRateController.text) ?? 0) / 100;
    }
    if (_enableCess) {
      total += amount * (double.tryParse(_cessRateController.text) ?? 0) / 100;
    }
    return total;
  }
}

class _TaxPreviewRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _TaxPreviewRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
