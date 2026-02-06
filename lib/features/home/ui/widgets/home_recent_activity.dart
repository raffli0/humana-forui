import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:humana/features/attendance/models/attendance_model.dart';

class HomeRecentActivityList extends StatelessWidget {
  final List<AttendanceModel> activities;

  const HomeRecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Aktivitas Terbaru",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HomeRecentActivityItem(activity: activity),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HomeRecentActivityItem extends StatelessWidget {
  final AttendanceModel activity;

  const HomeRecentActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<({String time, String label, bool isLate})> subItems = [
      (
        time: DateFormat("hh:mm a").format(activity.checkInTime),
        label: "Masuk",
        isLate: activity.status == "Late",
      ),
    ];

    if (activity.checkOutTime != null) {
      subItems.add((
        time: DateFormat("hh:mm a").format(activity.checkOutTime!),
        label: "Pulang",
        isLate: false,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: subItems.map((item) {
          final isLast = item == subItems.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.isLate ? colors.warning : colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  height: 30,
                  width: 1,
                  color: colors.border.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label + (item.isLate ? " (Terlambat)" : ""),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: item.isLate
                              ? colors.warning
                              : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.checkInLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity.checkInImageUrl.isNotEmpty &&
                    item.label == "Masuk")
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        activity.checkInImageUrl,
                        width: 44,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 32,
                          color: colors.surfaceVariant,
                          child: Icon(
                            Icons.broken_image,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
