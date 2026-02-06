import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:humana/shared/widgets/app_header.dart';
import 'scan_page.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../services/attendance_service.dart';

class CheckInActionPage extends StatelessWidget {
  const CheckInActionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy location (e.g. Jakarta)
    const LatLng center = LatLng(-6.2088, 106.8456);
    final attendanceService = AttendanceService();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final colors = context.colors;
        return Scaffold(
          backgroundColor:
              colors.accent, // Use brand color as splash background
          body: SafeArea(
            child: Column(
              children: [
                const AppHeader(title: "Current Location", showAvatar: false),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Headquarters",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Jl. Jend. Sudirman No. 1, Jakarta Pusat\nRadius: 50m - Within Range",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                              options: const MapOptions(
                                initialCenter: center,
                                initialZoom: 15,
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.shift',
                                  tileBuilder: (context, widget, tile) {
                                    return ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.grey,
                                        BlendMode.saturation,
                                      ),
                                      child: Opacity(
                                        opacity: 0.7,
                                        child: widget,
                                      ),
                                    );
                                  },
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: center,
                                      width: 48,
                                      height: 48,
                                      child: Icon(
                                        Icons.location_on,
                                        color: colors
                                            .textPrimary, // Changed from hardcoded for visibility on brand bg
                                        size: 48,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _CheckInButton(
                          onTap: () async {
                            final imagePath = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaceScanPage(),
                              ),
                            );

                            if (imagePath != null && context.mounted) {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Processing Check-in..."),
                                  ),
                                );

                                await attendanceService.checkIn(
                                  userId: authState.user?.id ?? "unknown",
                                  userName:
                                      authState.user?.fullName ?? "Unknown",
                                  companyId: authState.user?.companyId,
                                  location: "Headquarters",
                                  imageFile: File(imagePath),
                                  status: "On Time",
                                  latitude: center.latitude,
                                  longitude: center.longitude,
                                  insideOffice: true,
                                  shiftStart: "09:00",
                                  shiftEnd: "17:00",
                                  tolerance: 0,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Check-in successful!"),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e")),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
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
}

class _CheckInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CheckInButton({required this.onTap});

  @override
  State<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<_CheckInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color:
                colors.surface, // Use surface for button on branded background
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.face_retouching_natural, color: colors.textPrimary),
              const SizedBox(width: 12),
              Text(
                "Start Face Scan",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
