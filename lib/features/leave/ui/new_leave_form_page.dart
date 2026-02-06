import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:humana/shared/widgets/app_dialog.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/features/auth/services/auth_service.dart';
import 'package:humana/features/leave/services/leave_service.dart';
import 'package:humana/features/auth/models/user_model.dart';
import 'package:humana/features/auth/bloc/auth_bloc.dart';
import 'package:humana/core/theme/app_colors.dart';

class NewLeaveFormPage extends StatefulWidget {
  const NewLeaveFormPage({super.key});

  @override
  State<NewLeaveFormPage> createState() => _NewLeaveFormPageState();
}

class _NewLeaveFormPageState extends State<NewLeaveFormPage> {
  final _reasonController = TextEditingController();
  final _leaveService = LeaveService();
  final _authService = AuthService();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'Sakit';
  bool _isLoading = false;

  final _types = ['Sakit', 'Cuti Tahunan', 'Lainnya'];

  Future<void> _submitRequest() async {
    if (_startDate == null ||
        _endDate == null ||
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

      await _leaveService.submitLeaveRequest(
        user: user,
        type: _selectedType,
        reason: _reasonController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        companyId: user.companyId,
      );

      if (mounted) {
        await AppDialog.showSuccess(
          context: context,
          title: "Permintaan cuti terkirim",
          message: "Permintaan Anda menunggu persetujuan.",
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            const AppHeader(title: "Ajukan Cuti", showAvatar: false),
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
                        "Permintaan Cuti Baru",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Isi detail di bawah untuk mengajukan cuti.",
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jenis Cuti",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedType,
                                isExpanded: true,
                                dropdownColor: colors.surface,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                ),
                                items: _types.map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedType = v);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _DateInput(
                              label: "Tanggal Mulai",
                              value: _startDate,
                              colors: colors,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: colors.accent,
                                          onPrimary: Colors.white,
                                          surface: colors.surface,
                                          onSurface: colors.textPrimary,
                                        ),
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: colors.background,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DateInput(
                              label: "Tanggal Selesai",
                              value: _endDate,
                              colors: colors,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime.now(),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: colors.accent,
                                          onPrimary: Colors.white,
                                          surface: colors.surface,
                                          onSurface: colors.textPrimary,
                                        ),
                                        dialogTheme: DialogThemeData(
                                          backgroundColor: colors.background,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _endDate = date);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                          hintText: "Masukkan alasan cuti...",
                          hintStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colors.border.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colors.border.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colors.accent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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
