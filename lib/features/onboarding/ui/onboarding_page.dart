import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/ui/login_page.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onDone;

  const OnboardingPage({super.key, this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final LocationService _locationService = LocationService();
  int _currentPage = 0;
  bool _isRequestingPermission = false;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Selamat Datang di Humana",
      "subtitle": "Aplikasi simpel untuk karyawan\ndan pencari kerja.",
      "color": const Color(0xFF6366F1), // Indigo
      "icon": Icons.rocket_launch_rounded,
    },
    {
      "title": "Semua Bisa Disini",
      "subtitle": "Absen harian gampang, cari\nloker baru juga bisa.",
      "color": const Color(0xFF10B981), // Emerald
      "icon": Icons.people_alt_rounded,
    },
    {
      "title": "Izin Lokasi Dulu",
      "subtitle": "Nyalakan GPS kamu biar\nabsennya makin lancar.",
      "color": const Color(0xFFEF4444), // Rose
      "icon": Icons.location_on_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else {
      // Logic for the last page: Request Permission
      setState(() => _isRequestingPermission = true);

      try {
        // Just requesting position triggers the permission dialog
        await _locationService.getCurrentPosition();
        if (mounted) _finishOnboarding();
      } catch (e) {
        if (!mounted) return;
        // Show error but allow user to proceed or retry?
        // Let's show a snackbar and let them try again or maybe proceed anyway if they insist?
        // For now, let's just show the error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Izin lokasi diperlukan: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;

    // Execute callback if provided
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      // Fallback behavior (should not be used in main flow)
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 180),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    final color = data["color"] as Color;
                    final icon = data["icon"] as IconData;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 48, color: color),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            data["title"]!,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data["subtitle"]!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 18,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PAGE INDICATOR
                    Row(
                      children: List.generate(
                        _onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          height: 6,
                          width: _currentPage == index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colors.accent
                                : colors.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    // NEXT BUTTON
                    GestureDetector(
                      onTap: _isRequestingPermission ? null : _onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent, // Primary accent color
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isRequestingPermission
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                children: [
                                  Text(
                                    _currentPage == _onboardingData.length - 1
                                        ? "Mulai Sekarang"
                                        : "Lanjut",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
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
}
