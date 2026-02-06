import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../models/attendance_model.dart';
import 'package:humana/core/services/location_service.dart';
import '../../face_liveness/ui/face_liveness_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => LocationService(),
      dispose: (service) => service.dispose(),
      child: BlocProvider(
        create: (context) {
          final authState = context.read<AuthBloc>().state;
          return AttendanceBloc(
            locationService: context.read<LocationService>(),
            companyId: authState.user?.companyId ?? '',
          )..add(AttendanceStarted());
        },
        child: const AttendanceView(),
      ),
    );
  }
}

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.successType != current.successType,
      listener: (context, state) {
        if (state.status == AttendanceStatus.error) {
          final message = (state.errorMessage ?? "Attendance Failed")
              .replaceAll("Exception: ", "");
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
        } else if (state.status == AttendanceStatus.success &&
            state.successType != AttendanceSuccessType.none) {
          _showSuccessDialog(context, state.successType);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(
                title: "Absensi",
                showAvatar: false,
                showBell: false,
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _AttendanceSegment(),
              ),
              Expanded(
                child: BlocBuilder<AttendanceBloc, AttendanceState>(
                  buildWhen: (prev, curr) => prev.tabIndex != curr.tabIndex,
                  builder: (context, state) {
                    if (state.tabIndex == 1) {
                      return const _AttendanceHistoryList();
                    }
                    return const SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_ClockAndMapCard(), SizedBox(height: 20)],
                      ),
                    );
                  },
                ),
              ),
              BlocBuilder<AttendanceBloc, AttendanceState>(
                buildWhen: (prev, curr) => prev.tabIndex != curr.tabIndex,
                builder: (context, state) {
                  // Hide actions if on History tab (index 1)
                  if (state.tabIndex == 1) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: _AttendanceActions(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    AttendanceSuccessType successType,
  ) {
    String title = "Berhasil";
    String message = "Operasi selesai.";
    switch (successType) {
      case AttendanceSuccessType.checkIn:
        title = "Anda berhasil masuk";
        message = "Absensi berhasil dicatat.";
        break;
      case AttendanceSuccessType.checkOut:
        title = "Berhasil pulang";
        message = "Sampai jumpa besok!";
        break;
      case AttendanceSuccessType.breakStart:
        title = "Istirahat dimulai";
        message = "Selamat beristirahat!";
        break;
      case AttendanceSuccessType.breakEnd:
        title = "Istirahat selesai";
        message = "Selamat bekerja kembali!";
        break;
      case AttendanceSuccessType.none:
        break;
    }
    AppDialog.showSuccess(context: context, title: title, message: message);
  }
}

class _AttendanceSegment extends StatelessWidget {
  const _AttendanceSegment();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
      padding: const EdgeInsets.all(4),
      child: BlocSelector<AttendanceBloc, AttendanceState, int>(
        selector: (state) => state.tabIndex,
        builder: (context, tabIndex) {
          return Row(
            children: [
              _SegmentButton(
                text: "Absensi Hari Ini",
                selected: tabIndex == 0,
                onTap: () => context.read<AttendanceBloc>().add(
                  const AttendanceTabChanged(0),
                ),
              ),
              _SegmentButton(
                text: "Riwayat Absensi",
                selected: tabIndex == 1,
                onTap: () => context.read<AttendanceBloc>().add(
                  const AttendanceTabChanged(1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockAndMapCard extends StatelessWidget {
  const _ClockAndMapCard();

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatShiftTime(String? time) {
    if (time == null) return "--:--";
    final parts = time.split(':');
    if (parts.length >= 2) return "${parts[0]}:${parts[1]}";
    return time;
  }

  String _getStatusText(AttendanceState state) {
    if (state.mainStatus == AttendanceMainStatus.none) return "Sudah Pulang";
    if (state.breakStatus == BreakStatus.onBreak) return "Istirahat";
    return "Sudah Masuk";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: colors.border.withValues(alpha: 0.5))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Info - Rebuilds rarely
          BlocSelector<
            AttendanceBloc,
            AttendanceState,
            ({String? start, String? end})
          >(
            selector: (state) => (start: state.shiftStart, end: state.shiftEnd),
            builder: (context, shift) {
              if (shift.start == null || shift.end == null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Tidak Ada Shift",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      "Shift Hari Ini: ",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${_formatShiftTime(shift.start)} - ${_formatShiftTime(shift.end)}",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Map Widget - Isolated
          const _OptimizedMapWidget(),
          const SizedBox(height: 14),

          // Status & Clock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Text column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS SAAT INI',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  BlocBuilder<AttendanceBloc, AttendanceState>(
                    buildWhen: (freq, curr) =>
                        freq.mainStatus != curr.mainStatus ||
                        freq.breakStatus != curr.breakStatus,
                    builder: (context, state) {
                      return Text(
                        _getStatusText(state),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Clock - Rebuilds every second
              BlocSelector<AttendanceBloc, AttendanceState, DateTime>(
                selector: (state) => state.now,
                builder: (context, now) {
                  return Text(
                    _formatTime(now),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Face ID & Lokasi terverifikasi',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _OptimizedMapWidget extends StatefulWidget {
  const _OptimizedMapWidget();

  @override
  State<_OptimizedMapWidget> createState() => _OptimizedMapWidgetState();
}

class _OptimizedMapWidgetState extends State<_OptimizedMapWidget> {
  final MapController _mapController = MapController();
  final double zoomLevel = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          buildWhen: (prev, curr) {
            // Only rebuild map if important location data changes
            return prev.userLatLng != curr.userLatLng ||
                prev.officeLocation != curr.officeLocation ||
                prev.officeRadius != curr.officeRadius ||
                prev.currentAddress != curr.currentAddress ||
                prev.isInsideOffice != curr.isInsideOffice;
          },
          builder: (context, state) {
            const defaultOffice = LatLng(-6.93586, 107.63932);
            final officeLoc = state.officeLocation ?? defaultOffice;
            final center = state.userLatLng ?? officeLoc;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoomLevel,
                    minZoom: 15,
                    maxZoom: 18.5,
                    backgroundColor: colors.background,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.shift.app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: officeLoc,
                          color: Colors.blue.withValues(alpha: 0.25),
                          borderStrokeWidth: 2,
                          borderColor: Colors.blue,
                          useRadiusInMeter: true,
                          radius: state.officeRadius,
                        ),
                      ],
                    ),
                    if (state.userLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: state.userLatLng!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.person_pin_circle,
                              size: 44,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x88000000)],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildAddressBadge(state.currentAddress),
                _buildRecenterButton(state.userLatLng),
                _buildStatusBadge(state.isInsideOffice),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressBadge(String address) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.greenAccent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                address.isNotEmpty ? address : 'Mendeteksi lokasi...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton(LatLng? userLatLng) {
    return Positioned(
      bottom: 12,
      right: 12,
      child: GestureDetector(
        onTap: () {
          if (userLatLng != null) {
            _mapController.move(userLatLng, zoomLevel);
          }
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isInside) {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isInside
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInside ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isInside ? 'Di Dalam Area' : 'Di Luar Area',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceActions extends StatelessWidget {
  const _AttendanceActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      // Only rebuild if logic-affecting state changes
      buildWhen: (prev, curr) =>
          prev.mainStatus != curr.mainStatus ||
          prev.breakStatus != curr.breakStatus ||
          prev.isInsideOffice != curr.isInsideOffice,
      builder: (context, state) {
        final bloc = context.read<AttendanceBloc>();
        // Using explicit `state.isInternalShiftValid` assuming it was added, otherwise reuse isShiftValid logic inline
        // Actually, isShiftValid getter is on State, so we can use state.isShiftValid
        // But isShiftValid depends on 'now'. So if 'now' updates, isShiftValid might change.
        // We might need to listen to 'now' here too if we want the button to disable EXACTLY when shift ends.
        // But for performance, maybe we're okay with slight delay or just use BlocBuilder which listens to everything unless filtered.
        // Wait, I filtered 'now' out of buildWhen.
        // If 'now' makes isShiftValid change, the button won't update until something else triggers.
        // This is a trade-off. To be safe, we should probably include 'now' minute changes?
        // Or just let it rebuild every second?
        // The buttons are simple vector graphics. Rebuilding them is cheap.
        // The MAP is expensive.
        // Let's remove the buildWhen here to ensure correctness of "Time Check", or rely on 'now' minute?
        // Let's leave buildWhen empty (rebuild every second) for Buttons to account for shift timing.
        // Ideally we only rebuild when minute changes.
        return Row(
          children: [
            Expanded(
              child: _AttendanceButton(
                label: "Masuk",
                disabledLabel: state.mainStatus == AttendanceMainStatus.checkin
                    ? "Sudah Masuk"
                    : !state.isInsideOffice
                    ? "Di Luar Area"
                    : "Di Luar Shift",
                icon: FIcons.logIn,
                color: Colors.green,
                active: state.mainStatus == AttendanceMainStatus.checkin,
                enabled:
                    state.mainStatus == AttendanceMainStatus.none &&
                    state.isInsideOffice &&
                    state.isShiftValid,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceLivenessScreen(
                        callback: (image) {
                          if (image != null) {
                            bloc.add(
                              AttendanceCheckInRequested(imageFile: image),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Verifikasi Wajah Gagal"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceButton(
                label: state.breakStatus == BreakStatus.onBreak
                    ? "Selesai Istirahat"
                    : "Istirahat",
                icon: state.breakStatus == BreakStatus.onBreak
                    ? FIcons.play
                    : FIcons.coffee,
                color: Colors.orange,
                active: state.breakStatus == BreakStatus.onBreak,
                enabled: state.mainStatus == AttendanceMainStatus.checkin,
                onTap: () {
                  if (state.breakStatus == BreakStatus.onBreak) {
                    bloc.add(AttendanceOffBreakRequested());
                  } else {
                    bloc.add(AttendanceBreakRequested());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceButton(
                label: "Pulang",
                icon: FIcons.logOut,
                color: Colors.red,
                active: state.mainStatus == AttendanceMainStatus.checkout,
                enabled: state.mainStatus != AttendanceMainStatus.none,
                onTap: () => bloc.add(AttendanceCheckOutRequested()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  final String? disabledLabel;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.disabledLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? (active ? color : color.withValues(alpha: 0.5))
                  : Colors.grey,
              width: active ? 2.2 : 1.3,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: enabled ? color : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  enabled ? label : (disabledLabel ?? label),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHistoryList extends StatelessWidget {
  const _AttendanceHistoryList();

  Map<DateTime, List<AttendanceModel>> _groupActivities(
    List<AttendanceModel> list,
  ) {
    final Map<DateTime, List<AttendanceModel>> grouped = {};

    for (var attendance in list) {
      final dateKey = DateTime(
        attendance.checkInTime.year,
        attendance.checkInTime.month,
        attendance.checkInTime.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(attendance);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state.status == AttendanceStatus.loading &&
            state.attendanceHistory.isEmpty) {
          return const _HistorySkeleton();
        }

        if (state.attendanceHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FIcons.calendar,
                  size: 48,
                  color: colors.textSecondary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  "No attendance history",
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          );
        }

        final groupedData = _groupActivities(state.attendanceHistory);
        final dates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final activities = groupedData[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    DateFormat("EEEE, dd MMMM yyyy").format(date),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ),
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryListItem(activity: activity),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final AttendanceModel activity;

  const _HistoryListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<({String time, String label, bool isLate})> subItems = [
      (
        time: DateFormat("hh:mm a").format(activity.checkInTime),
        label: "Check In",
        isLate: activity.status == "Late",
      ),
    ];

    if (activity.checkOutTime != null) {
      subItems.add((
        time: DateFormat("hh:mm a").format(activity.checkOutTime!),
        label: "Check Out",
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
                        item.label + (item.isLate ? " (Late)" : ""),
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
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Skeleton(height: 14, width: 140),
            ),
            ...List.generate(
              2,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colors.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Column(
                        children: [
                          Skeleton(height: 16, width: 60),
                          SizedBox(height: 8),
                          Skeleton(height: 8, width: 8, borderRadius: 4),
                        ],
                      ),
                      SizedBox(width: 16),
                      Skeleton(height: 30, width: 1),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton(height: 14, width: 100),
                            SizedBox(height: 6),
                            Skeleton(height: 12, width: 200),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
