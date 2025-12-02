import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/money_provider.dart';
import '../utils/app_theme.dart';
import '../services/export_service.dart';
import '../services/update_service.dart';
import 'design_playground_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _checkingForUpdates = false;
  String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) {
      setState(() {
        _currentVersion = version;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (!mounted) return;

      setState(() {
        _checkingForUpdates = false;
      });

      if (updateInfo == null) {
        UpdateService.showErrorDialog(context);
      } else if (updateInfo.updateAvailable) {
        UpdateService.showUpdateDialog(context, updateInfo);
      } else {
        UpdateService.showUpToDateDialog(context, updateInfo.currentVersion);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
        UpdateService.showErrorDialog(context);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck && isSupported;
      });
    } catch (e) {
      setState(() {
        _canCheckBiometrics = false;
      });
    }
  }

  Future<void> _toggleBiometricLock(bool enable, MoneyProvider provider) async {
    if (enable) {
      // Verify biometric before enabling
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to enable biometric lock',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (didAuthenticate) {
          await provider.setBiometricLock(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric lock enabled'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enable: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await provider.setBiometricLock(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric lock disabled')),
        );
      }
    }
  }

  Future<void> _exportData(String format) async {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final exportService = ExportService();

    try {
      String? filePath;
      if (format == 'CSV') {
        filePath = await exportService.exportToCSV(provider.transactions);
      } else if (format == 'PDF') {
        filePath = await exportService.exportToPDF(
          provider.transactions,
          currencySymbol: provider.currencySymbol,
        );
      } else if (format == 'JSON') {
        filePath = await exportService.exportToJSON(provider.transactions);
      }

      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported to: PennyWise folder\n$filePath'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Export failed: Storage permission denied or error occurred',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final provider = Provider.of<MoneyProvider>(context, listen: false);
    final exportService = ExportService();

    try {
      // Pick file
      final file = await exportService.pickImportFile();
      if (file == null) {
        return; // User cancelled
      }

      if (file.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not access file path'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Determine file type and import
      ImportResult result;
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'csv') {
        result = await exportService.importFromCSV(
          file.path!,
          userId: provider.userId,
        );
      } else if (extension == 'json') {
        result = await exportService.importFromJSON(
          file.path!,
          userId: provider.userId,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported file format. Use CSV or JSON.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (result.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errors.isNotEmpty
                    ? 'Import failed: ${result.errors.first}'
                    : 'No transactions found in file',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show preview dialog
      if (mounted) {
        final shouldImport = await _showImportPreviewDialog(result);
        if (shouldImport == true) {
          // Import transactions
          int imported = 0;
          for (final transaction in result.transactions) {
            try {
              await provider.addTransaction(transaction);
              imported++;
            } catch (e) {
              debugPrint('Failed to import transaction: $e');
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported $imported transactions'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showImportPreviewDialog(ImportResult result) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Import Preview',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${result.successfulRows} of ${result.totalRows} transactions',
                style: const TextStyle(color: Colors.white70),
              ),
              if (result.hasErrors) ...[
                const SizedBox(height: 8),
                Text(
                  '${result.errors.length} rows had errors',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Preview:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.transactions.length > 5
                      ? 5
                      : result.transactions.length,
                  itemBuilder: (context, index) {
                    final t = result.transactions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            t.isExpense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: t.isExpense ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${t.isExpense ? '-' : '+'}${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: t.isExpense ? Colors.red : Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (result.transactions.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  '... and ${result.transactions.length - 5} more',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Import ${result.transactions.length}'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildUpdateTile(),
          const SizedBox(height: 24),

          _buildSection('Security'),
          _buildSwitchTile(
            'Biometric Lock',
            _canCheckBiometrics
                ? 'Require fingerprint or face to open app'
                : 'Not available on this device',
            Icons.fingerprint,
            provider.biometricLockEnabled,
            _canCheckBiometrics
                ? (value) => _toggleBiometricLock(value, provider)
                : null,
          ),
          const SizedBox(height: 24),

          _buildSection('Data'),
          _buildActionTile(
            'Import Transactions',
            'Import from CSV or JSON file',
            Icons.file_upload,
            _importData,
          ),
          _buildActionTile(
            'Export to CSV',
            'Download transaction history',
            Icons.file_download,
            () => _exportData('CSV'),
          ),
          _buildActionTile(
            'Export to JSON',
            'Export as JSON file',
            Icons.code,
            () => _exportData('JSON'),
          ),
          _buildActionTile(
            'Export to PDF',
            'Generate PDF report',
            Icons.picture_as_pdf,
            () => _exportData('PDF'),
          ),
          const SizedBox(height: 24),
          _buildSection('Developer'),
          _buildActionTile(
            'Design Playground',
            'Preview card designs',
            Icons.palette,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DesignPlaygroundScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('About'),
          _buildInfoTile('Version', _currentVersion),
          _buildInfoTile('Developer', 'Dark'),
        ],
      ),
    );
  }

  Widget _buildUpdateTile() {
    return GestureDetector(
      onTap: _checkingForUpdates ? null : _checkForUpdates,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check for Updates',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: v$_currentVersion',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_checkingForUpdates)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            else
              Icon(Icons.refresh, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    void Function(bool)? onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
