import 'package:flutter/material.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:humana/core/theme/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotif = false;
  bool locationTracking = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        centerTitle: true,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              title: 'NOTIFIKASI',
              colors: colors,
              child: Column(
                children: [
                  SwitchListTile(
                    value: pushNotif,
                    onChanged: (v) => setState(() => pushNotif = v),
                    secondary: const _SettingsIcon(
                      icon: Icons.notifications_none,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Notifikasi Push',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    activeThumbColor: colors.accent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _Divider(colors: colors),
                  SwitchListTile(
                    value: locationTracking,
                    onChanged: (v) => setState(() => locationTracking = v),
                    secondary: const _SettingsIcon(
                      icon: Icons.location_on_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(
                      'Pelacakan Lokasi',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    activeThumbColor: colors.accent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _section(
              title: 'TAMPILAN',
              colors: colors,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService().themeMode,
                builder: (context, mode, child) {
                  final isDark = ThemeService().isDarkMode;
                  return SwitchListTile(
                    value: isDark,
                    onChanged: (v) => ThemeService().setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    ),
                    title: Text(
                      'Mode Gelap',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'Mengikuti tema gelap' : 'Mengikuti tema terang',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    activeThumbColor: colors.accent,
                    secondary: const _SettingsIcon(
                      icon: Icons.dark_mode_outlined,
                      color: Colors.purple,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _section(
              title: 'KEAMANAN',
              colors: colors,
              child: Column(
                children: [
                  _NavTile(
                    icon: Icons.lock_outline,
                    color: Colors.redAccent,
                    title: 'Ubah Kata Sandi',
                    onTap: () {
                      Navigator.pushNamed(context, '/change-password');
                    },
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _section(
              title: 'APLIKASI',
              colors: colors,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.info_outline,
                    color: Colors.teal,
                    label: 'Versi Aplikasi',
                    value: '1.0.0',
                    colors: colors,
                  ),
                  _Divider(colors: colors),
                  _InfoTile(
                    icon: Icons.numbers,
                    color: Colors.teal,
                    label: 'Nomor Build',
                    value: '1',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final AppColors colors;
  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: colors.border.withValues(alpha: 0.2));
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final AppColors colors;

  const _NavTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingsIcon(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colors.textSecondary,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final AppColors colors;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingsIcon(icon: icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
          fontSize: 14,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
