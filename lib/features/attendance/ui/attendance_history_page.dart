import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'package:humana/core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../attendance/services/attendance_service.dart';
import '../../attendance/models/attendance_model.dart';

class _ActivityItemModel {
  final String time;
  final String description;
  final String location;
  final String imageUrl;
  final bool isLate;

  _ActivityItemModel({
    required this.time,
    required this.description,
    required this.location,
    required this.imageUrl,
    this.isLate = false,
  });
}

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late Future<List<AttendanceModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthBloc>().state.user?.id ?? '';
    _historyFuture = AttendanceService().getUserAttendance(userId);
  }

  Map<DateTime, List<_ActivityItemModel>> _groupActivities(
    List<AttendanceModel> list,
  ) {
    final Map<DateTime, List<_ActivityItemModel>> grouped = {};

    for (var attendance in list) {
      final dateKey = DateTime(
        attendance.checkInTime.year,
        attendance.checkInTime.month,
        attendance.checkInTime.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      // Add Check In
      grouped[dateKey]!.add(
        _ActivityItemModel(
          time: DateFormat("hh:mm a").format(attendance.checkInTime),
          description: "Masuk",
          location: attendance.checkInLocation,
          imageUrl: attendance.checkInImageUrl,
          isLate:
              attendance.status ==
              "Late", // Keep logic but consider status string might need mapping if API returns English
        ),
      );

      // Add Check Out if exists
      if (attendance.checkOutTime != null) {
        grouped[dateKey]!.add(
          _ActivityItemModel(
            time: DateFormat("hh:mm a").format(attendance.checkOutTime!),
            description: "Pulang",
            location: attendance.checkOutLocation ?? "Tidak diketahui",
            imageUrl: attendance.checkOutImageUrl ?? "",
          ),
        );
      }
    }
    return grouped;
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
              title: "Riwayat",
              showAvatar: false,
              showBell: false,
            ),
            Expanded(
              child: FutureBuilder<List<AttendanceModel>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Gagal memuat riwayat",
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Tidak ada riwayat kehadiran",
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    );
                  }

                  final groupedData = _groupActivities(snapshot.data!);
                  final dates = groupedData.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final activities = groupedData[date]!;

                      // Sort activities by time descending within the day if desired,
                      // but typically Check In is first then Check Out.
                      // Loop added them in order (Check In then Check Out).
                      // If we want reverse chronological (latest first), reverse the list.
                      // Let's keep chronological for the day flow (Check In -> Check Out).

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DATE HEADER
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              DateFormat("EEEE, dd MMMM yyyy").format(date),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // LIST ITEMS
                          ...activities.map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryItem(
                                activity: activity,
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final _ActivityItemModel activity;
  final AppColors colors;

  const _HistoryItem({required this.activity, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        children: [
          // TIME & INDICATOR
          Column(
            children: [
              Text(
                activity.time,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activity.isLate ? colors.warning : colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // DASHED LINE SEPARATOR
          Container(
            height: 40,
            width: 1,
            color: colors.border.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description +
                      (activity.isLate ? " (Terlambat)" : ""),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: activity.isLate
                        ? colors.warning
                        : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.location,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
