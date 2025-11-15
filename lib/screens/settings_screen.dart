import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/custom_widgets.dart';
import 'login_screen.dart';
import 'tax_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'INR (₹)';

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 35,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin User',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall / 2),
                          Text(
                            'admin@ashirwad.com',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall / 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                            ),
                            child: const Text(
                              'Administrator',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Navigate to edit profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit profile functionality coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Company Information
            Text(
              'Company Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Card(
              child: Column(
                children: [
                  _SettingsListTile(
                    title: 'Company Details',
                    subtitle: 'Update company information',
                    icon: Icons.business,
                    onTap: () {
                      _showCompanyInfo();
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsListTile(
                    title: 'Tax Settings',
                    subtitle: 'Configure tax rates and company info',
                    icon: Icons.receipt_long,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TaxSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // App Preferences
            Text(
              'App Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable app notifications'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_rupee),
                    title: const Text('Currency'),
                    subtitle: Text(_selectedCurrency),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showCurrencySelector();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Data Management
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Card(
              child: Column(
                children: [
                  _SettingsListTile(
                    title: 'Clear Cache',
                    subtitle: 'Clear app cache and temporary files',
                    icon: Icons.cleaning_services,
                    onTap: () {
                      _showClearCacheDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Support & About
            Text(
              'Support & About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            Card(
              child: Column(
                children: [
                  _SettingsListTile(
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    icon: Icons.help,
                    onTap: () {
                      // TODO: Navigate to help
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & support functionality coming soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsListTile(
                    title: 'Privacy Policy',
                    subtitle: 'View privacy policy',
                    icon: Icons.privacy_tip,
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsListTile(
                    title: 'About App',
                    subtitle: 'Version 1.0.0',
                    icon: Icons.info,
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Logout Button
            CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              onPressed: _logout,
              isSecondary: true,
            ),

            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  void _showCompanyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: Ashirwad Industries'),
            SizedBox(height: 8),
            Text('Business: Plastic Granules Manufacturing'),
            SizedBox(height: 8),
            Text('GST No: GST123456789012345'),
            SizedBox(height: 8),
            Text('Address: Industrial Area, Mumbai'),
            SizedBox(height: 8),
            Text('Contact: +91 9876543210'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to edit company info
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'INR (₹)',
            'USD (\$)',
            'EUR (€)',
            'GBP (£)',
          ].map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data and temporary files. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.business,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: const [
        Text('Billing management app for Ashirwad Industries'),
        SizedBox(height: 8),
        Text('Developed for plastic granules manufacturing business'),
      ],
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
