import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:forui/forui.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/payslip_model.dart';
import '../services/payroll_service.dart';
import 'payslip_detail_page.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  final PayrollService _service = PayrollService();
  late Future<List<PayslipModel>> _futurePayslips;
  String _selectedFilter = "All";
  final List<String> _filters = [
    "All",
    "Draft",
    "Processing",
    "Pending",
    "Paid",
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _futurePayslips = _service.getPayslips();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'Semua';
      case 'draft':
        return 'Konsep';
      case 'processing':
        return 'Diproses';
      case 'pending':
        return 'Menunggu';
      case 'paid':
        return 'Dibayar';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: "Penggajian",
              showAvatar: false,
              showBell: false,
            ),
            Expanded(
              child: FutureBuilder<List<PayslipModel>>(
                future: _futurePayslips,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _PayrollSkeleton();
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Terjadi Kesalahan: ${snapshot.error}",
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    );
                  }

                  final allPayslips = snapshot.data ?? [];
                  final payslips = _selectedFilter == "All"
                      ? allPayslips
                      : allPayslips
                            .where(
                              (p) =>
                                  p.status.toLowerCase() ==
                                  _selectedFilter.toLowerCase(),
                            )
                            .toList();

                  // Latest Payslip Header
                  final latest = allPayslips.isNotEmpty
                      ? allPayslips.first
                      : null;
                  final currencyFormat = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Highlight Card
                        if (latest != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF10B981), // Emerald Primary
                                  Color(0xFF059669), // Emerald Dark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        FIcons.banknote,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    _buildBadge(
                                      _translateStatus(latest.status),
                                      textColor: _getStatusColor(latest.status),
                                      bgColor: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Gaji Terakhir",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(latest.netSalary),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        FIcons.calendar,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        latest.period,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((filter) {
                              final isSelected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedFilter = filter),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colors.accent
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : colors.border.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      _translateStatus(filter),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          "RIWAYAT",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (payslips.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                "Tidak ada data untuk filter ini",
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          )
                        else
                          // History List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: payslips.length,
                            itemBuilder: (context, index) {
                              final slip = payslips[index];
                              final statusColor = _getStatusColor(slip.status);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colors.border.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    if (Theme.of(context).brightness ==
                                        Brightness.light)
                                      BoxShadow(
                                        color: colors.textPrimary.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PayslipDetailPage(payslip: slip),
                                      ),
                                    ).then((_) {
                                      setState(() {
                                        _futurePayslips = _service
                                            .getPayslips();
                                      });
                                    });
                                  },
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      FIcons.banknote,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    slip.period,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd MMM',
                                        ).format(slip.paymentDate),
                                        style: TextStyle(
                                          color: colors.textTertiary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: colors.border,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _translateStatus(slip.status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(slip.netSalary),
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        color: colors.textTertiary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    String text, {
    Color? color,
    Color? textColor,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? (color ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (textColor ?? color ?? Colors.grey).withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? color ?? Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PayrollSkeleton extends StatelessWidget {
  const _PayrollSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton(height: 36, width: 36, borderRadius: 12),
                    Skeleton(height: 24, width: 80, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 24),
                Skeleton(height: 14, width: 100),
                SizedBox(height: 8),
                Skeleton(height: 32, width: 200),
                SizedBox(height: 16),
                Skeleton(height: 30, width: 120, borderRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Filters Skeleton
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                4,
                (index) => const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Skeleton(height: 36, width: 80, borderRadius: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Skeleton(height: 12, width: 60),
          const SizedBox(height: 16),
          // History List Skeleton
          ...List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.1),
                ),
              ),
              child: const Row(
                children: [
                  Skeleton(height: 40, width: 40, borderRadius: 12),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(height: 15, width: 120),
                        SizedBox(height: 8),
                        Skeleton(height: 12, width: 180),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Skeleton(height: 14, width: 80),
                      SizedBox(height: 8),
                      Skeleton(height: 16, width: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
