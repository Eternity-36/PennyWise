import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ExportService {
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), try MANAGE_EXTERNAL_STORAGE for full file access
      var manageStatus = await Permission.manageExternalStorage.status;

      if (!manageStatus.isGranted) {
        // Request MANAGE_EXTERNAL_STORAGE permission
        final result = await Permission.manageExternalStorage.request();

        if (result.isGranted) {
          return true;
        }

        // If denied, check if permanently denied and open settings
        if (result.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        // If not granted and not permanently denied, try regular storage permission as fallback
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          final storageResult = await Permission.storage.request();

          if (!storageResult.isGranted) {
            if (storageResult.isPermanentlyDenied) {
              await openAppSettings();
            }
            return false;
          }
          return storageResult.isGranted;
        }
        return storageStatus.isGranted;
      }

      return true; // MANAGE_EXTERNAL_STORAGE already granted
    }
    return true; // iOS doesn't need explicit storage permission
  }

  Future<Directory?> _getPennyWiseDirectory() async {
    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        // Try to get external storage directory (internal storage on device)
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          // Navigate to the root of internal storage
          final String externalPath = externalDirs.first.path;
          // Extract path up to Android/data/...
          final parts = externalPath.split('/');
          final androidIndex = parts.indexOf('Android');
          if (androidIndex > 0) {
            final basePath = parts.sublist(0, androidIndex).join('/');
            baseDir = Directory('$basePath/PennyWise');
          }
        }

        // Fallback to app-specific directory
        if (baseDir == null) {
          final appDir = await getApplicationDocumentsDirectory();
          baseDir = Directory('${appDir.path}/PennyWise');
        }
      } else {
        // iOS: Use documents directory
        final appDir = await getApplicationDocumentsDirectory();
        baseDir = Directory('${appDir.path}/PennyWise');
      }

      // Create directory if it doesn't exist
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      return baseDir;
    } catch (e) {
      debugPrint('Error creating PennyWise directory: $e');
      return null;
    }
  }

  Future<String?> exportToCSV(List<Transaction> transactions) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final List<List<dynamic>> rows = [
        ['Date', 'Title', 'Category', 'Amount', 'Type'],
      ];

      for (var t in transactions) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(t.date),
          t.title,
          t.category,
          t.amount.toStringAsFixed(2),
          t.isExpense ? 'Expense' : 'Income',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);

      // Get PennyWise directory
      final directory = await _getPennyWiseDirectory();
      if (directory == null) {
        return null;
      }

      final fileName =
          'pennywise_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      debugPrint('CSV export error: $e');
      return null;
    }
  }

  Future<String?> exportToPDF(List<Transaction> transactions, {String currencySymbol = '₹'}) async {
    try {
      // Request permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return null;
      }

      final pdf = pw.Document();
      final currencyFormat = NumberFormat.currency(
        symbol: currencySymbol,
        decimalDigits: 2,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PennyWise Transaction Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Title', 'Category', 'Amount', 'Type'],
                  data: transactions
                      .map(
                        (t) => [
                          DateFormat('yyyy-MM-dd').format(t.date),
                          t.title,
                          t.category,
                          currencyFormat.format(t.amount),
                          t.isExpense ? 'Expense' : 'Income',
                        ],
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      );

      // Get PennyWise directory
      final directory = await _getPennyWiseDirectory();
      if (directory == null) {
        return null;
      }

      final fileName =
          'pennywise_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      debugPrint('PDF export error: $e');
      return null;
    }
  }
}
