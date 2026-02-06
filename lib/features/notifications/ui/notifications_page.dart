import 'package:humana/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifications = [
      _NotifItem(
        title: "Leave Approved",
        body: "Your sick leave request for Oct 24 - 26 has been approved.",
        time: "2 hours ago",
        type: _NotifType.success,
        colors: colors,
      ),
      _NotifItem(
        title: "Check In Reminder",
        body: "Don't forget to check in before 09:15 AM.",
        time: "5 hours ago",
        type: _NotifType.info,
        colors: colors,
      ),
      _NotifItem(
        title: "Shift Update",
        body: "Your shift on Nov 01 has been swapped with Sarah J.",
        time: "1 day ago",
        type: _NotifType.warning,
        colors: colors,
      ),
      _NotifItem(
        title: "Payslip Available",
        body: "Your payslip for September 2025 is now available.",
        time: "2 days ago",
        type: _NotifType.info,
        colors: colors,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: "Notifications",
              showAvatar: false,
              showBell: false,
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return notifications[index];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotifType { success, info, warning, error }

class _NotifItem extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final _NotifType type;
  final AppColors colors;

  const _NotifItem({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.colors,
  });

  Color _getColor() {
    switch (type) {
      case _NotifType.success:
        return colors.success; // Green
      case _NotifType.warning:
        return colors.warning; // Yellow
      case _NotifType.error:
        return colors.error; // Red
      case _NotifType.info:
        return colors.accent; // Purple
    }
  }

  IconData _getIcon() {
    switch (type) {
      case _NotifType.success:
        return Icons.check_circle_outline_rounded;
      case _NotifType.warning:
        return Icons.warning_amber_rounded;
      case _NotifType.error:
        return Icons.error_outline_rounded;
      case _NotifType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
