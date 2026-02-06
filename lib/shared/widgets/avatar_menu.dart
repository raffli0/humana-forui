import 'package:humana/core/theme/app_colors.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';

void showAvatarMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // IMPORTANT
    barrierColor: Colors.black.withValues(alpha: 0.35), // optional dim
    builder: (context) {
      final colors = context.colors;
      final user = context.read<AuthBloc>().state.user;
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            color: colors.surface,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),

              // Avatar & Identity
              Builder(
                builder: (context) {
                  final photoUrl = user?.profilePhotoUrl;
                  final initials = user != null && user.fullName.isNotEmpty
                      ? user.fullName
                            .split(' ')
                            .take(2)
                            .map((e) => e[0])
                            .join()
                            .toUpperCase()
                      : '??';

                  return Column(
                    children: [
                      FAvatar(
                        size: 80, // Increased size
                        image: NetworkImage(
                          photoUrl ??
                              'https://ui-avatars.com/api/?name=$initials&background=020817&color=fff&size=128',
                        ),
                        fallback: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 32,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? "User",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role.toUpperCase() ?? "KARYAWAN",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Menu Items
              _menuItem(
                icon: FIcons.user,
                text: "Lihat Profil",
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/profile");
                },
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: FIcons.settings,
                text: "Pengaturan",
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/settings");
                },
              ),

              const SizedBox(height: 24),
              Divider(color: colors.border.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 24),

              // Destructive Action
              _menuItem(
                icon: FIcons.logOut,
                text: "Keluar",
                color: colors.error,
                colors: colors,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _menuItem({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
  required AppColors colors,
  Color? color,
  bool isDestructive = false,
}) {
  final itemColor = color ?? colors.textPrimary;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isDestructive
            ? BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? colors.error.withValues(alpha: 0.1)
                    : colors.border.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: itemColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: itemColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isDestructive) ...[
              const Spacer(),
              Icon(
                FIcons.chevronRight,
                size: 16,
                color: colors.textTertiary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
