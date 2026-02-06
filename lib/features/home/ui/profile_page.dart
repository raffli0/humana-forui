import 'package:humana/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/core/widgets/skeleton.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/ui/login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../attendance/services/attendance_service.dart';
import '../../../core/theme/theme_service.dart';

class ProfilePage extends StatefulWidget {
  final bool showBackButton;

  const ProfilePage({super.key, this.showBackButton = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _handlePhotoUpload(BuildContext context) async {
    final colors = context.colors;
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.textPrimary),
              title: Text(
                'Ambil foto',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, image);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.textPrimary),
              title: Text(
                'Pilih dari galeri',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx, image);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null && context.mounted) {
      context.read<AuthBloc>().add(
        AuthProfilePhotoUpdateRequested(File(image.path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = context.select((AuthBloc bloc) => bloc.state);
    final user = authState.user;
    final companyName = authState.companyName;
    final isCandidate = user?.role == 'candidate';

    if (authState.status == AuthStatus.loading || user == null) {
      return const _ProfileSkeleton();
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? BackButton(color: colors.textPrimary)
            : null,
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showEditDialog(context, user, companyName),
            child: Text(
              'Ubah',
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets
              .zero, // Remove default padding to allow header to stretch
          child: Column(
            children: [
              _profileHeader(
                context,
                user.fullName,
                user.role,
                user.profilePhotoUrl,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!isCandidate) ...[
                      _quickActions(context),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 6,
                        ),
                        child: Text(
                          "Data wajah Anda digunakan untuk verifikasi absensi yang aman dan cepat.",
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _section(
                      context,
                      title: 'INFORMASI KONTAK',
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.email,
                            color: Colors.blue,
                            title: 'Email',
                            value: user.email,
                            onTap: () => _showSingleFieldEditDialog(
                              context,
                              title: 'Ubah Email',
                              label: 'Email',
                              initialValue: user.email,
                              onSave: (value) {
                                context.read<AuthBloc>().add(
                                  AuthProfileUpdateRequested(
                                    fullName: user.fullName,
                                    email: value,
                                    phone: user.phone,
                                    department: user.department,
                                    manager: user.manager,
                                    companyName: companyName,
                                  ),
                                );
                              },
                            ),
                          ),
                          const _Divider(),
                          _InfoTile(
                            icon: Icons.phone,
                            color: Colors.green,
                            title: 'Nomor Telepon',
                            value: user.phone ?? 'Belum diatur',
                            onTap: () => _showSingleFieldEditDialog(
                              context,
                              title: 'Ubah Nomor Telepon',
                              label: 'Nomor Telepon',
                              initialValue: user.phone ?? '',
                              onSave: (value) {
                                context.read<AuthBloc>().add(
                                  AuthProfileUpdateRequested(
                                    fullName: user.fullName,
                                    email: user.email,
                                    phone: value,
                                    department: user.department,
                                    manager: user.manager,
                                    companyName: companyName,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCandidate) ...[
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'DETAIL PEKERJAAN',
                        child: Column(
                          children: [
                            _RowTile(
                              label: 'Departemen',
                              value: user.department ?? 'Belum diatur',
                            ),
                            const _Divider(),
                            _RowTile(
                              label: 'Perusahaan',
                              value: companyName ?? 'Belum diatur',
                            ),
                            const _Divider(),
                            _RowTile(
                              label: 'ID Karyawan',
                              value: (user.employeeCode?.isNotEmpty ?? false)
                                  ? user.employeeCode!
                                  : (user.employeeId ?? 'Belum diatur'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'PREFERENSI',
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeService().themeMode,
                          builder: (context, mode, child) {
                            final isDark = ThemeService().isDarkMode;
                            return SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isDark ? Icons.dark_mode : Icons.light_mode,
                                  color: colors.textPrimary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                'Mode Gelap',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: isDark,
                              activeTrackColor: colors.accent,
                              onChanged: (val) {
                                ThemeService().setThemeMode(
                                  val ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'OPSI PENGEMBANG',
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.delete_forever,
                              color: Colors.redAccent,
                              title: 'Reset Semua Absensi',
                              value: 'Hapus semua riwayat saya',
                              onTap: () =>
                                  _handleResetAttendance(context, user.id),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Candidate specific sections if any, or just Dark Mode
                      const SizedBox(height: 24),
                      _section(
                        context,
                        title: 'PREFERENSI',
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeService().themeMode,
                          builder: (context, mode, child) {
                            final isDark = ThemeService().isDarkMode;
                            return SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isDark ? Icons.dark_mode : Icons.light_mode,
                                  color: colors.textPrimary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                'Mode Gelap',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: isDark,
                              activeTrackColor: colors.accent,
                              onChanged: (val) {
                                ThemeService().setThemeMode(
                                  val ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                        ),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'App Version 1.1 (Build 2)',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... existing methods like _showSingleFieldEditDialog ...
  Future<void> _handleResetAttendance(
    BuildContext context,
    String? userId,
  ) async {
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        title: Text(
          'Reset Absensi?',
          style: TextStyle(color: ctx.colors.textPrimary),
        ),
        content: Text(
          'Ini akan menghapus SEMUA catatan absensi Anda secara permanen. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: ctx.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(color: ctx.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AttendanceService().deleteAllUserAttendance(userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua catatan absensi dihapus.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi Kesalahan: $e')));
        }
      }
    }
  }

  void _showSingleFieldEditDialog(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required Function(String) onSave,
  }) {
    // ... implementation
    // Truncated for brevity, assuming standard dialogs
    final controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        title: Text(
          title,
          style: TextStyle(color: dialogContext.colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            style: TextStyle(color: dialogContext.colors.textPrimary),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: dialogContext.colors.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: dialogContext.colors.textSecondary,
                ),
              ),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(color: dialogContext.colors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.colors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    dynamic user,
    String? currentCompanyName,
  ) {
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final deptController = TextEditingController(text: user.department ?? '');
    final companyController = TextEditingController(
      text: currentCompanyName ?? '',
    );
    final isAdmin = user.role == 'admin';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        title: Text(
          'Ubah Profil',
          style: TextStyle(color: dialogContext.colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: dialogContext.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  labelStyle: TextStyle(
                    color: dialogContext.colors.textSecondary,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: dialogContext.colors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: deptController,
                  style: TextStyle(color: dialogContext.colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Departemen',
                    labelStyle: TextStyle(
                      color: dialogContext.colors.textSecondary,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: dialogContext.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: companyController,
                  style: TextStyle(color: dialogContext.colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nama Perusahaan',
                    labelStyle: TextStyle(
                      color: dialogContext.colors.textSecondary,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: dialogContext.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(color: dialogContext.colors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogContext.colors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<AuthBloc>().add(
                AuthProfileUpdateRequested(
                  fullName: nameController.text,
                  email: user.email,
                  phone: user.phone,
                  department: isAdmin ? deptController.text : user.department,
                  manager: user
                      .manager, // Keep existing manager value, do not update from UI
                  companyName: isAdmin ? companyController.text : null,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(
    BuildContext context,
    String? name,
    String? role,
    String? photoUrl,
  ) {
    final colors = context.colors;
    final isCandidate = role == 'candidate';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surfaceVariant.withValues(alpha: 0.5),
            colors.background,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _handlePhotoUpload(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52, // Increased size
                    backgroundColor: colors.surfaceVariant,
                    backgroundImage: photoUrl != null
                        ? CachedNetworkImageProvider(photoUrl)
                        : NetworkImage(
                                'https://i.pravatar.cc/300?u=${name ?? "User"}',
                              )
                              as ImageProvider,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _handlePhotoUpload(context),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.accent,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name ?? 'User',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24, // Increased size
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCandidate ? 'PELAMAR' : (role?.toUpperCase() ?? 'KARYAWAN'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AKTIF • Bandung, Indonesia',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        _actionButton(context, Icons.badge_outlined, 'Lihat Kartu ID'),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.05), // Tinted background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.accent.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary, // Or accent
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ],
    );
  }
}

/* ===== SMALL COMPONENTS ===== */

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.textTertiary.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final String label;
  final String value;

  const _RowTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      title: Text(label, style: TextStyle(color: colors.textSecondary)),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: context.colors.border.withValues(alpha: 0.1),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.colors.background,
        centerTitle: true,
        title: const Skeleton(height: 20, width: 100),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: const Column(
                children: [
                  Skeleton(height: 104, width: 104, borderRadius: 52),
                  SizedBox(height: 16),
                  Skeleton(height: 24, width: 150),
                  SizedBox(height: 8),
                  Skeleton(height: 14, width: 80),
                  SizedBox(height: 16),
                  Skeleton(height: 32, width: 200, borderRadius: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(
                    height: 56,
                    width: double.infinity,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 32),
                  const Skeleton(height: 12, width: 120),
                  const SizedBox(height: 16),
                  ...List.generate(
                    2,
                    (index) => const Column(
                      children: [
                        Skeleton(
                          height: 48,
                          width: double.infinity,
                          borderRadius: 8,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Skeleton(height: 12, width: 120),
                  const SizedBox(height: 16),
                  ...List.generate(
                    3,
                    (index) => const Column(
                      children: [
                        Skeleton(
                          height: 48,
                          width: double.infinity,
                          borderRadius: 8,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
