import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../core/theme/app_colors.dart';
import 'avatar_menu.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showAvatar;
  final bool showBell;
  final VoidCallback? onBellTap;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.showAvatar = true,
    this.showBell = true,
    this.onBellTap,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors
            .background, // Ensure solid background for sticky effect if needed
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // CENTER TITLE
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // LEFT ACTION (Avatar or Back)
              if (onBack != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: onBack,
                  ),
                )
              else if (showAvatar)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => showAvatarMenu(context),
                    child: Builder(
                      builder: (context) {
                        final user = context.select(
                          (AuthBloc bloc) => bloc.state.user,
                        );
                        final initials =
                            user != null && user.fullName.isNotEmpty
                            ? user.fullName
                                  .split(' ')
                                  .take(2)
                                  .map((e) => e[0])
                                  .join()
                                  .toUpperCase()
                            : '??';

                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.border.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            color: colors.surfaceVariant,
                          ),
                          child: FAvatar(
                            size: 32,
                            image: NetworkImage(
                              user?.profilePhotoUrl ??
                                  'https://ui-avatars.com/api/?name=$initials&background=020817&color=fff&size=128',
                            ),
                            fallback: Text(initials),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // RIGHT ACTIONS (Bell)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBell)
                      IconButton(
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll<Color>(
                            Colors.transparent,
                          ),
                        ),
                        icon: Icon(
                          FIcons.bell,
                          size: 24,
                          color: colors.textPrimary,
                        ),
                        onPressed:
                            onBellTap ??
                            () {
                              Navigator.pushNamed(context, '/notif');
                            },
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
}
