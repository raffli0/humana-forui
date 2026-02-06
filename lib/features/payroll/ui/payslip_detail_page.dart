import 'package:flutter/material.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../models/payslip_model.dart';
import '../services/payroll_service.dart';

class PayslipDetailPage extends StatefulWidget {
  final PayslipModel payslip;

  const PayslipDetailPage({super.key, required this.payslip});

  @override
  State<PayslipDetailPage> createState() => _PayslipDetailPageState();
}

class _PayslipDetailPageState extends State<PayslipDetailPage> {
  late PayslipModel _currentPayslip;
  final PayrollService _service = PayrollService();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentPayslip = widget.payslip;
  }

  Color _getStatusColor(AppColors colors, String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return colors.success;
      case 'processing':
        return colors.accent;
      case 'pending':
        return colors.warning;
      case 'cancelled':
        return colors.error;
      case 'draft':
        return colors.textSecondary;
      default:
        return colors.textSecondary;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _service.updatePayslipStatus(_currentPayslip.id, newStatus);
      setState(() {
        _currentPayslip = _currentPayslip.copyWith(status: newStatus);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final isAdmin = user?.role == 'admin';

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy');

    final colors = context.colors;
    final statusColor = _getStatusColor(colors, _currentPayslip.status);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payslip Details",
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: Icon(Icons.edit_note, color: colors.textPrimary),
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                'Draft',
                'Processing',
                'Pending',
                'Paid',
                'Cancelled',
              ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentPayslip.period,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormat.format(_currentPayslip.netSalary),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _currentPayslip.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 24),

                // --- EMPLOYEE INFO ---
                _buildCard(
                  colors,
                  title: "Employee Details",
                  children: [
                    _buildDetailItem(
                      colors,
                      "NIK",
                      _currentPayslip.nik.isNotEmpty
                          ? _currentPayslip.nik
                          : "-",
                    ),
                    _buildDetailItem(
                      colors,
                      "NPWP",
                      _currentPayslip.npwp.isNotEmpty
                          ? _currentPayslip.npwp
                          : "-",
                    ),
                    _buildDetailItem(
                      colors,
                      "Status",
                      _currentPayslip.employmentStatus.isNotEmpty
                          ? _currentPayslip.employmentStatus
                          : "-",
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- EARNINGS ---
                _buildCard(
                  colors,
                  title: "Earnings",
                  children: [
                    _buildDetailItem(
                      colors,
                      "Basic Salary",
                      currencyFormat.format(_currentPayslip.basicSalary),
                    ),
                    if (_currentPayslip.positionAllowance > 0)
                      _buildDetailItem(
                        colors,
                        "Position Allowance",
                        currencyFormat.format(
                          _currentPayslip.positionAllowance,
                        ),
                        isPositive: true,
                      ),
                    if (_currentPayslip.transportAllowance > 0)
                      _buildDetailItem(
                        colors,
                        "Transport Allowance",
                        currencyFormat.format(
                          _currentPayslip.transportAllowance,
                        ),
                        isPositive: true,
                      ),
                    if (_currentPayslip.mealAllowance > 0)
                      _buildDetailItem(
                        colors,
                        "Meal Allowance",
                        currencyFormat.format(_currentPayslip.mealAllowance),
                        isPositive: true,
                      ),
                    if (_currentPayslip.bpjsHealthAllowance > 0)
                      _buildDetailItem(
                        colors,
                        "BPJS Health (Co.)",
                        currencyFormat.format(
                          _currentPayslip.bpjsHealthAllowance,
                        ),
                        isPositive: true,
                      ),
                    if (_currentPayslip.bpjsLaborAllowance > 0)
                      _buildDetailItem(
                        colors,
                        "BPJS Labor (Co.)",
                        currencyFormat.format(
                          _currentPayslip.bpjsLaborAllowance,
                        ),
                        isPositive: true,
                      ),
                    if (_currentPayslip.overtime > 0)
                      _buildDetailItem(
                        colors,
                        "Overtime",
                        currencyFormat.format(_currentPayslip.overtime),
                        isPositive: true,
                      ),
                    if (_currentPayslip.bonus > 0)
                      _buildDetailItem(
                        colors,
                        "Bonus",
                        currencyFormat.format(_currentPayslip.bonus),
                        isPositive: true,
                      ),
                    if (_currentPayslip.otherAllowances > 0)
                      _buildDetailItem(
                        colors,
                        "Other Allowances",
                        currencyFormat.format(_currentPayslip.otherAllowances),
                        isPositive: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- DEDUCTIONS ---
                _buildCard(
                  colors,
                  title: "Deductions",
                  children: [
                    if (_currentPayslip.bpjsHealthDeduction > 0)
                      _buildDetailItem(
                        colors,
                        "BPJS Health",
                        "- ${currencyFormat.format(_currentPayslip.bpjsHealthDeduction)}",
                        isPositive: false,
                      ),
                    if (_currentPayslip.bpjsLaborDeduction > 0)
                      _buildDetailItem(
                        colors,
                        "BPJS Labor",
                        "- ${currencyFormat.format(_currentPayslip.bpjsLaborDeduction)}",
                        isPositive: false,
                      ),
                    if (_currentPayslip.taxDeduction > 0)
                      _buildDetailItem(
                        colors,
                        "PPh 21 Tax",
                        "- ${currencyFormat.format(_currentPayslip.taxDeduction)}",
                        isPositive: false,
                      ),
                    if (_currentPayslip.loanDeduction > 0)
                      _buildDetailItem(
                        colors,
                        "Loan Repayment",
                        "- ${currencyFormat.format(_currentPayslip.loanDeduction)}",
                        isPositive: false,
                      ),
                    // Fallback for aggregate 'deductions' field
                    if (_currentPayslip.deductions > 0 &&
                        _currentPayslip.bpjsHealthDeduction == 0 &&
                        _currentPayslip.bpjsLaborDeduction == 0 &&
                        _currentPayslip.taxDeduction == 0 &&
                        _currentPayslip.loanDeduction == 0)
                      _buildDetailItem(
                        colors,
                        "Total Deductions",
                        "- ${currencyFormat.format(_currentPayslip.deductions)}",
                        isPositive: false,
                      ),
                    if (_currentPayslip.deductions == 0 &&
                        _currentPayslip.bpjsHealthDeduction == 0 &&
                        _currentPayslip.bpjsLaborDeduction == 0 &&
                        _currentPayslip.taxDeduction == 0 &&
                        _currentPayslip.loanDeduction == 0)
                      _buildDetailItem(colors, "No Deductions", "-"),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: colors.border.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment Date",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      dateFormat.format(_currentPayslip.paymentDate),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Download Button (Mock)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Downloading PDF... (Mock)"),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: colors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(
    AppColors colors, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    AppColors colors,
    String label,
    String value, {
    bool? isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPositive == null
                  ? colors.textPrimary
                  : (isPositive ? colors.success : colors.error),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
