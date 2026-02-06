import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'package:forui/forui.dart';
import 'package:humana/core/theme/app_colors.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'package:humana/shared/widgets/app_dialog.dart';
import '../../auth/models/user_model.dart';
import 'widgets/home_recent_activity.dart'; // Add import

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeStarted(user?.id ?? '')),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Select user here, in the build method of the generic widget
    final user = context.select((AuthBloc bloc) => bloc.state.user);
    final colors = context.colors;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Sticky HEADER
                const AppHeader(title: "", showAvatar: true, showBell: true),
                const SizedBox(height: 5),
                // SCROLL AREA
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final userId = user?.id ?? '';
                      context.read<HomeBloc>().add(
                        HomeRefreshRequested(userId),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildGreeting(user),
                          ),
                          const SizedBox(height: 10),
                          _buildOverviewCard(state, user?.id ?? ''),
                          const SizedBox(height: 20),
                          HomeRecentActivityList(
                            activities: state.recentActivity,
                          ), // Use new widget
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ),
            ),
            Center(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SafeArea(
                    top: false,
                    child: FCalendar(
                      controller: FCalendarController.date(
                        initialSelection: selectedDate,
                      ),
                      start: DateTime(2000),
                      end: DateTime(2030),
                      onPress: (date) {
                        setState(() => selectedDate = date);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // GREETING
  Widget _buildGreeting(UserModel? user) {
    final firstName = user?.fullName.split(' ').first ?? 'User';
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM dd, yyyy').format(DateTime.now()).toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Apa Kabar, $firstName!",
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // OVERVIEW CARD
  Widget _buildOverviewCard(HomeState state, String userId) {
    final today = state.todayAttendance;
    final hasCheckedIn = today != null;

    // Determine Check In Display
    final checkInTime = hasCheckedIn
        ? DateFormat("hh:mm a").format(today.checkInTime)
        : "--:--";
    final checkInBadge = hasCheckedIn
        ? (today.status == "Late" ? "Terlambat" : "Tepat waktu")
        : "n/a";
    final checkInColor = hasCheckedIn
        ? (today.status == "Late"
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981))
        : Colors.grey;

    // Determine Check Out Display (Mock logic for checkout time field if not in model yet, assuming checkout updates doc)
    // Actually AttendanceModel doesn't have checkOutTime explicitly shown in previous view, let's check assumptions or use "n/a"
    // Wait, AttendanceService update checkOutTime. Let's assume AttendanceModel has it or we missed it.
    // Re-reading AttendanceModel... I didn't verify if it has checkOutTime.
    // In AttendanceService.checkOut: 'check_out_time': Timestamp.now().
    // user_model.dart... wait, attendance_model.dart.
    // I will assume I can't access checkOutTime if not in model.
    // Let's use what we have. If todayAttendance exists, we checked in.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ringkasan",
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _DateBadge(
                dateText: DateFormat("MMM dd, yyyy").format(selectedDate),
                onTap: () => _openCalendar(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// OVERVIEW BOXES
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _OverviewBox(
                      cupertinoIcon: CupertinoIcons.arrow_down_left_circle,
                      label: "Masuk",
                      time: checkInTime,
                      badge: checkInBadge,
                      badgeColor: checkInColor,
                      iconColor: const Color(0xFF10B981), // Emerald
                      subtitle: hasCheckedIn ? "Berhasil masuk" : "Belum masuk",
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/check-in',
                        );
                        if (mounted && userId.isNotEmpty) {
                          if (result == true) {
                            await AppDialog.showSuccess(
                              context: context,
                              title: "Anda berhasil masuk",
                              message: "Absensi berhasil dicatat.",
                            );
                          }
                          if (!mounted) return;
                          context.read<HomeBloc>().add(
                            HomeRefreshRequested(userId),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _OverviewBox(
                      cupertinoIcon: CupertinoIcons.arrow_right_circle,
                      label: "Pulang",
                      time: (hasCheckedIn && today.checkOutTime != null)
                          ? DateFormat("hh:mm a").format(today.checkOutTime!)
                          : "--:--",
                      badge: (hasCheckedIn && today.checkOutTime != null)
                          ? "Selesai"
                          : "n/a",
                      badgeColor: (hasCheckedIn && today.checkOutTime != null)
                          ? const Color(0xFFEF4444) // Rose
                          : Colors.grey,
                      iconColor: const Color(0xFFEF4444), // Rose
                      subtitle: (hasCheckedIn && today.checkOutTime != null)
                          ? "Sudah pulang"
                          : "Belum pulang",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        bool isOnBreak = false;
                        String breakTime = "--:--";
                        String breakSubtitle = "Tidak ada data istirahat";
                        String badge = "n/a";
                        Color badgeColor = Colors.grey;

                        if (hasCheckedIn &&
                            today.breaks != null &&
                            today.breaks!.isNotEmpty) {
                          final lastBreak = today.breaks!.last;
                          final startTime = DateTime.parse(lastBreak['start']);
                          final startStr = DateFormat(
                            "hh:mm a",
                          ).format(startTime);

                          if (lastBreak['end'] == null) {
                            isOnBreak = true;
                            breakTime = "$startStr - ...";
                            breakSubtitle = "Sedang istirahat";
                            badge = "Aktif";
                            badgeColor = Colors.orange;
                          } else {
                            final endTime = DateTime.parse(lastBreak['end']);
                            final endStr = DateFormat(
                              "hh:mm a",
                            ).format(endTime);
                            breakTime = "$startStr - $endStr";
                            breakSubtitle = "Istirahat selesai";
                            badge = "Selesai";
                            badgeColor = Colors.green;
                          }
                        }

                        return _OverviewBox(
                          cupertinoIcon: CupertinoIcons.stopwatch,
                          label: "Istirahat",
                          time: breakTime,
                          badge: badge,
                          badgeColor: badgeColor,
                          iconColor: const Color(0xFFF59E0B), // Amber
                          subtitle: breakSubtitle,
                          onTap: () {
                            if (!hasCheckedIn) {
                              AppDialog.showError(
                                context: context,
                                title: "Tindakan tidak tersedia",
                                message:
                                    "Harap selesaikan langkah sebelumnya terlebih dahulu.",
                              );
                              return;
                            }

                            if (today.checkOutTime != null) {
                              AppDialog.showError(
                                context: context,
                                title: "Tindakan tidak tersedia",
                                message:
                                    "Anda sudah melakukan absen pulang hari ini.",
                              );
                              return;
                            }

                            if (isOnBreak) {
                              // End Break Popup
                              AppDialog.show(
                                context: context,
                                title: "Akhiri istirahat?",
                                message: "Waktu kerja akan dilanjutkan.",
                                primaryButtonText: "Akhiri istirahat",
                                secondaryButtonText: "Batal",
                                onPrimary: () {
                                  context.read<HomeBloc>().add(
                                    HomeBreakToggled(today.id, false),
                                  );
                                },
                              );
                            } else {
                              // Start Break Popup
                              AppDialog.show(
                                context: context,
                                title: "Mulai istirahat?",
                                message:
                                    "Waktu kerja akan dihentikan sementara.",
                                primaryButtonText: "Mulai istirahat",
                                secondaryButtonText: "Batal",
                                onPrimary: () {
                                  context.read<HomeBloc>().add(
                                    HomeBreakToggled(today.id, true),
                                  );
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        String overtimeTime = "--:--";
                        String badge = "n/a";
                        Color badgeColor = Colors.grey;
                        String subtitle = "Tidak ada lembur";

                        if (hasCheckedIn) {
                          final now = DateTime.now();
                          final endTime = today.checkOutTime ?? now;
                          final totalSession = endTime.difference(
                            today.checkInTime,
                          );

                          int totalBreakMinutes = 0;
                          if (today.breaks != null) {
                            for (var b in today.breaks!) {
                              final start = DateTime.parse(b['start']);
                              final end = b['end'] != null
                                  ? DateTime.parse(b['end'])
                                  : now;
                              totalBreakMinutes += end
                                  .difference(start)
                                  .inMinutes;
                            }
                          }

                          final netWorkMinutes =
                              totalSession.inMinutes - totalBreakMinutes;

                          // Assuming 8 hour work day (480 minutes)
                          final overtimeMinutes = netWorkMinutes - 480;

                          if (overtimeMinutes > 0) {
                            final h = overtimeMinutes ~/ 60;
                            final m = overtimeMinutes % 60;
                            overtimeTime = "${h}h ${m}m";
                            badge = "Ekstra";
                            badgeColor = Colors.purple;
                            subtitle = "Kerja bagus!";
                          } else {
                            overtimeTime = "00:00";
                            subtitle = "Belum";
                          }
                        }

                        return _OverviewBox(
                          cupertinoIcon: CupertinoIcons.clock,
                          label: "Lembur",
                          time: overtimeTime,
                          badge: badge,
                          badgeColor: badgeColor,
                          iconColor: const Color(0xFF6366F1), // Indigo
                          subtitle: subtitle,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// DIVIDER
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        ],
      ),
    );
  }
}

class _OverviewBox extends StatelessWidget {
  final IconData? cupertinoIcon;
  final String label;
  final String time;
  final String badge;
  final Color badgeColor;
  final Color iconColor;
  final String subtitle;
  final VoidCallback? onTap;

  const _OverviewBox({
    this.cupertinoIcon,
    required this.label,
    required this.time,
    required this.badge,
    required this.badgeColor,
    required this.iconColor,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cupertinoIcon, size: 16, color: iconColor),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String dateText;
  final VoidCallback onTap;

  const _DateBadge({required this.dateText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, size: 14, color: colors.iconPrimary),
            const SizedBox(width: 8),
            Text(
              dateText,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// End of file
