import 'package:flutter/material.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/features/auth/services/auth_service.dart';
import 'package:humana/features/auth/models/user_model.dart';
import 'package:humana/features/auth/bloc/auth_bloc.dart';
import 'package:humana/shared/widgets/app_dialog.dart';
import 'package:humana/shared/widgets/app_header.dart';
import '../services/shift_swap_service.dart';

class NewShiftSwapPage extends StatefulWidget {
  const NewShiftSwapPage({super.key});

  @override
  State<NewShiftSwapPage> createState() => _NewShiftSwapPageState();
}

class _NewShiftSwapPageState extends State<NewShiftSwapPage> {
  final _reasonController = TextEditingController();
  final _targetColleagueController = TextEditingController();
  final _shiftSwapService = ShiftSwapService();
  final _authService = AuthService();

  DateTime? _myShiftDate;
  DateTime? _targetShiftDate;
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (_myShiftDate == null ||
        _targetShiftDate == null ||
        _targetColleagueController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon isi semua kolom"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserModel? user;
      try {
        final authBloc = context.read<AuthBloc>();
        user = authBloc.state.user;
      } catch (_) {}

      user ??= await _authService.checkAuthStatus();

      if (user == null) {
        final supabaseUser = _authService.currentUser;
        if (supabaseUser == null) {
          throw Exception("Pengguna tidak terautentikasi");
        }
        user = UserModel(
          id: supabaseUser.id,
          fullName: supabaseUser.userMetadata?['full_name'] ?? "User",
          email: supabaseUser.email ?? "",
          role: "employee",
        );
      }

      await _shiftSwapService.submitShiftSwapRequest(
        requesterId: user.id,
        requesterName: user.fullName,
        myShiftDate: _myShiftDate!,
        targetShiftDate:
            _targetShiftDate!, // For now using same date or different? Usually swap implies swapping shifts, maybe on different days or same day different time.
        targetUserId: 'TBD', // Placeholder or search logic
        targetUserName: _targetColleagueController.text,
        reason: _reasonController.text,
        companyId: user.companyId,
      );

      if (mounted) {
        await AppDialog.showSuccess(
          context: context,
          title: "Permintaan tukar shift terkirim",
          message: "Permintaan Anda menunggu persetujuan.",
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            const AppHeader(title: "Ajukan Tukar Shift", showAvatar: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Permintaan Tukar Shift Baru",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ajukan penukaran shift dengan rekan kerja.",
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // My Shift Date
                      _DateInput(
                        label: "Tanggal Shift Saya",
                        value: _myShiftDate,
                        colors: colors,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (date != null) {
                            setState(() => _myShiftDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Target Colleague
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tukar Dengan (Nama Rekan)",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetColleagueController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: "cth. Budi Santoso",
                              hintStyle: TextStyle(color: colors.textSecondary),
                              filled: true,
                              fillColor: colors.surface,
                              border: _buildBorder(colors),
                              enabledBorder: _buildBorder(colors),
                              focusedBorder: _buildBorder(
                                colors,
                                color: colors.accent,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Target Shift Date
                      _DateInput(
                        label: "Tanggal Shift Mereka",
                        value: _targetShiftDate,
                        colors: colors,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _myShiftDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (date != null) {
                            setState(() => _targetShiftDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Reason Input
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: "Alasan",
                          labelStyle: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: "Masukkan alasan penukaran...",
                          hintStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.surface,
                          border: _buildBorder(colors),
                          enabledBorder: _buildBorder(colors),
                          focusedBorder: _buildBorder(
                            colors,
                            color: colors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      GestureDetector(
                        onTap: _isLoading ? null : _submitRequest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? colors.textSecondary.withValues(alpha: 0.5)
                                : colors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Ajukan Permintaan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
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

  InputBorder _buildBorder(
    AppColors colors, {
    Color? color,
    double width = 1.0,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color ?? colors.border.withValues(alpha: 0.2),
        width: width,
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final AppColors colors;

  const _DateInput({
    required this.label,
    required this.value,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat("MMM dd, yyyy").format(value!)
                        : "Pilih Tanggal",
                    style: TextStyle(
                      color: value != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
