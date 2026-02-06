import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:humana/features/leave/ui/leave_detail_page.dart';
import 'package:humana/features/leave/ui/new_leave_form_page.dart';
import 'package:humana/features/request/ui/new_overtime_page.dart';
import 'package:humana/features/request/ui/new_shift_swap_page.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:humana/core/widgets/skeleton.dart';
import '../../leave/services/leave_service.dart';
import '../../leave/models/leave_request_model.dart';
import '../services/overtime_service.dart';
import '../services/shift_swap_service.dart';
import '../../auth/services/auth_service.dart';

// Unified Model for List
class RequestListItem {
  final String id;
  final String type; // 'Sick Leave', 'Overtime', 'Shift Swap', etc.
  final DateTime date; // Sortable date (Start date, or request date)
  final DateTime? endDate; // Optional end date for ranges
  final String status;
  final DateTime createdAt;
  final String title;
  final String subtitle;
  final dynamic originalModel; // Keep reference to original model for details

  RequestListItem({
    required this.id,
    required this.type,
    required this.date,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.title,
    required this.subtitle,
    required this.originalModel,
  });
}

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  int filterIndex = 0;
  final filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  final _leaveService = LeaveService();
  final _overtimeService = OvertimeService();
  final _shiftSwapService = ShiftSwapService();
  final _authService = AuthService();

  List<RequestListItem> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final user = await _authService.checkAuthStatus();
      if (user != null) {
        // Fetch all types in parallel
        final results = await Future.wait([
          _leaveService.getMyRequests(user.id),
          _overtimeService.getMyOvertimeRequests(user.id),
          _shiftSwapService.getMyShiftSwapRequests(user.id),
        ]);

        final leaves = results[0] as List<LeaveRequestModel>;
        final overtimes =
            results[1]
                as dynamic; // Using dynamic to avoid import issues if type check fails
        final shiftSwaps = results[2] as dynamic;

        final List<RequestListItem> allRequests = [];

        // Map Leaves
        allRequests.addAll(
          leaves.map(
            (l) => RequestListItem(
              id: l.id,
              type: l.type,
              date: l.startDate,
              endDate: l.endDate,
              status: l.status,
              createdAt: l.createdAt,
              title: l.type,
              subtitle: _formatDateRange(l.startDate, l.endDate),
              originalModel: l,
            ),
          ),
        );

        // Map Overtime
        for (final o in overtimes) {
          allRequests.add(
            RequestListItem(
              id: o.id,
              type: 'Overtime',
              date: o.date,
              status: o.status,
              createdAt: o.createdAt,
              title: 'Overtime',
              subtitle:
                  "${DateFormat("MMM dd").format(o.date)} • ${o.durationMinutes} mnt",
              originalModel: o,
            ),
          );
        }

        // Map Shift Swaps
        for (final s in shiftSwaps) {
          allRequests.add(
            RequestListItem(
              id: s.id,
              type: 'Shift Swap',
              date: s.myShiftDate,
              status: s.status,
              createdAt: s.createdAt,
              title: 'Shift Swap',
              subtitle:
                  "Tukar ${DateFormat("MMM dd").format(s.myShiftDate)} dgn ${s.targetUserName}",
              originalModel: s,
            ),
          );
        }

        // Sort by CreatedAt descending (or Date descending)
        allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mounted) {
          setState(() {
            _requests = allRequests;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading requests: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat permintaan";
          _isLoading = false;
        });
      }
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
              title: "Permintaan",
              showAvatar: false,
              showBell: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("BUAT BARU"),
                    const SizedBox(height: 12),
                    _buildCreateNew(),

                    const SizedBox(height: 24),
                    _buildFilter(),

                    const SizedBox(height: 24),
                    _sectionTitle("RIWAYAT TERBARU"),
                    const SizedBox(height: 12),

                    SizedBox(
                      // Explicit height/constraints handled by parent usually, but here just robust list
                      child: _buildRequestList(),
                    ),
                    const SizedBox(height: 48), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    if (_isLoading) {
      return const _RequestSkeleton();
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: context.colors.error),
        ),
      );
    }

    // Filter requests
    final filtered = _requests.where((r) {
      if (filterIndex == 0) return true; // All
      final status = r.status.toLowerCase();
      if (filterIndex == 1) return status == 'pending';
      if (filterIndex == 2) return status == 'approved';
      if (filterIndex == 3) return status == 'rejected';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            "Tidak ada permintaan",
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _RequestHistoryCard(
          item: item,
          icon: _getIconForType(item.type),
          statusColor: _getColorForStatus(item.status),
          submitted:
              "Diajukan ${DateFormat("MMM dd, yyyy").format(item.createdAt)}",
        );
      },
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat("MMM dd").format(start);
    }
    return "${DateFormat("MMM dd").format(start)} - ${DateFormat("MMM dd").format(end)}";
  }

  IconData _getIconForType(String type) {
    if (type.toLowerCase().contains('leave')) {
      if (type.toLowerCase().contains('sick')) return Icons.medical_services;
      if (type.toLowerCase().contains('annual')) return Icons.beach_access;
      return Icons.event_busy;
    }
    switch (type.toLowerCase()) {
      case 'overtime':
        return Icons.timer;
      case 'shift swap':
        return Icons.swap_horiz;
      default:
        return Icons.event;
    }
  }

  Color _getColorForStatus(String status) {
    final colors = context.colors;
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

  Widget _sectionTitle(String text) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1,
      ),
    );
  }

  /// ================= CREATE NEW =================
  Widget _buildCreateNew() {
    return Row(
      children: [
        Expanded(
          child: _NewRequestButton(
            onTap: () {
              _showCreateRequestSheet(context);
            },
          ),
        ),
      ],
    );
  }

  /// ================= FILTER =================
  Widget _buildFilter() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = filterIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => filterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NewRequestButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewRequestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permintaan Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cuti, Lembur, Tukar Shift',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

void _showCreateRequestSheet(BuildContext context) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RequestActionTile(
              icon: Icons.flight_takeoff,
              title: 'Ajukan Cuti',
              onTap: () {
                Navigator.pop(context); // Close sheet before push
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewLeaveFormPage()),
                );
              },
            ),
            _RequestActionTile(
              icon: Icons.timer,
              title: 'Lembur',
              onTap: () {
                Navigator.pop(context); // Close sheet before push
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewOvertimePage()),
                );
              },
            ),
            _RequestActionTile(
              icon: Icons.swap_horiz,
              title: 'Tukar Shift',
              onTap: () {
                Navigator.pop(context); // Close sheet before push
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewShiftSwapPage()),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _RequestActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _RequestActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(icon, color: colors.accent, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: colors.textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
      onTap: onTap,
    );
  }
}

/// ================= HISTORY CARD =================
class _RequestHistoryCard extends StatelessWidget {
  final RequestListItem item;
  final IconData icon;
  final Color statusColor;
  final String submitted;

  const _RequestHistoryCard({
    required this.item,
    required this.icon,
    required this.statusColor,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.isNotEmpty ? _translateStatus(item.status) : '',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                submitted,
                style: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (item.originalModel is LeaveRequestModel) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LeaveStatusPage(request: item.originalModel),
                      ),
                    );
                  } else {
                    // Show basic info dialog for now
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: colors.surface,
                        title: Text(
                          item.title,
                          style: TextStyle(color: colors.textPrimary),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status: ${item.status}",
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Details: ${item.subtitle}",
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              "Tutup",
                              style: TextStyle(color: colors.accent),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text(
                  "Lihat Detail ›",
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
            : '';
    }
  }
}

class _RequestSkeleton extends StatelessWidget {
  const _RequestSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.1),
            ),
          ),
          child: const Row(
            children: [
              Skeleton(height: 48, width: 48, borderRadius: 16),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Skeleton(height: 16, width: 80),
                        Skeleton(height: 12, width: 60),
                      ],
                    ),
                    SizedBox(height: 8),
                    Skeleton(height: 12, width: 120),
                    SizedBox(height: 8),
                    Skeleton(height: 14, width: 60, borderRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
