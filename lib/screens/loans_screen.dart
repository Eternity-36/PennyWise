import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/money_provider.dart';
import '../models/loan.dart';
import '../utils/app_theme.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);
    final loans = provider.loans;
    final givenLoans = loans.where((l) => l.type == LoanType.given).toList();
    final takenLoans = loans.where((l) => l.type == LoanType.taken).toList();
    final totalLent = provider.totalLent;
    final totalBorrowed = provider.totalBorrowed;

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Loans', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Given (Lent)'),
            Tab(text: 'Taken (Borrowed)'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, provider, totalLent, totalBorrowed),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoanList(context, provider, givenLoans, LoanType.given),
                _buildLoanList(context, provider, takenLoans, LoanType.taken),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLoanDialog(context, provider),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    MoneyProvider provider,
    double totalLent,
    double totalBorrowed,
  ) {
    final currency = provider.currencySymbol;
    final netBalance = totalLent - totalBorrowed;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            const Color(0xFF2D3459).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(
                  symbol: currency,
                  decimalDigits: 0,
                ).format(netBalance),
                style: TextStyle(
                  color: netBalance >= 0 ? AppTheme.income : AppTheme.expense,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100,
            width: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.expense,
                    value: totalLent > 0 ? totalLent : 1,
                    title: '',
                    radius: 15,
                  ),
                  PieChartSectionData(
                    color: AppTheme.income,
                    value: totalBorrowed > 0 ? totalBorrowed : 1,
                    title: '',
                    radius: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildLoanList(
    BuildContext context,
    MoneyProvider provider,
    List<Loan> loans,
    LoanType type,
  ) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == LoanType.given ? Icons.outbond : Icons.call_received,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              type == LoanType.given
                  ? 'No loans given yet'
                  : 'No loans taken yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _buildLoanCard(context, provider, loan);
      },
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    MoneyProvider provider,
    Loan loan,
  ) {
    final currency = provider.currencySymbol;
    final progress = loan.progress;
    final isCompleted = loan.isCompleted;

    return Dismissible(
      key: Key(loan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              'Delete Loan?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteLoan(loan.id);
      },
      child: GestureDetector(
        onTap: () => _showEditLoanDialog(context, provider, loan),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loan.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: currency,
                      decimalDigits: 0,
                    ).format(loan.totalAmount),
                    style: TextStyle(
                      color: loan.type == LoanType.given
                          ? AppTheme.expense
                          : AppTheme.income,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid: ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(loan.paidAmount)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Remaining: ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(loan.remainingAmount)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : AppTheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              if (loan.dueDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Due: ${DateFormat('MMM d, y').format(loan.dueDate!)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  void _showAddLoanDialog(BuildContext context, MoneyProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    LoanType selectedType = _tabController.index == 0
        ? LoanType.given
        : LoanType.taken;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Add Loan', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title (e.g., Person Name)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Type:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  DropdownButton<LoanType>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: LoanType.given,
                        child: Text('Given (Lent)'),
                      ),
                      DropdownMenuItem(
                        value: LoanType.taken,
                        child: Text('Taken (Borrowed)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedDate == null
                      ? 'Select Due Date (Optional)'
                      : 'Due: ${DateFormat('MMM d, y').format(selectedDate!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    final newLoan = Loan(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      totalAmount: amount,
                      type: selectedType,
                      startDate: DateTime.now(),
                      dueDate: selectedDate,
                    );
                    provider.addLoan(newLoan);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLoanDialog(
    BuildContext context,
    MoneyProvider provider,
    Loan loan,
  ) {
    final paidController = TextEditingController(
      text: loan.paidAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Update ${loan.title}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total Amount: ${provider.currencySymbol}${loan.totalAmount}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paidController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Paid Amount',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final paid = double.tryParse(paidController.text) ?? 0;
              if (paid >= 0 && paid <= loan.totalAmount) {
                loan.paidAmount = paid;
                provider.updateLoan(loan);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
