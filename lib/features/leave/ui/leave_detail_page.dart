import 'package:flutter/material.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'package:humana/core/theme/app_colors.dart';
import '../../leave/models/leave_request_model.dart';
import 'package:intl/intl.dart';

class LeaveStatusPage extends StatelessWidget {
  final LeaveRequestModel request;

  const LeaveStatusPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: "Detail Permintaan",
              showAvatar: false,
              showBell: false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // STATUS BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            request.status,
                            colors,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _capitalize(request.status),
                          style: TextStyle(
                            color: _getStatusColor(request.status, colors),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        request.type,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diajukan pada ${DateFormat("MMM dd, yyyy").format(request.createdAt)}",
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 32),

                      _DetailRow(
                        label: "Dari",
                        value: DateFormat(
                          "MMM dd, yyyy",
                        ).format(request.startDate),
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: "Sampai",
                        value: DateFormat(
                          "MMM dd, yyyy",
                        ).format(request.endDate),
                        colors: colors,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: "Total Hari",
                        value:
                            "${request.endDate.difference(request.startDate).inDays + 1} Hari",
                        colors: colors,
                      ),

                      if (request.reason.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          "Alasan",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.reason,
                          style: TextStyle(
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],

                      if (request.adminNote != null &&
                          request.adminNote!.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          "Catatan Admin",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.adminNote!,
                          style: TextStyle(
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, AppColors colors) {
    switch (status.toLowerCase()) {
      case 'pending':
        return colors.warning;
      case 'approved':
        return colors.success;
      case 'rejected':
        return colors.error;
      default:
        return colors.textSecondary;
    }
  }

  String _capitalize(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
