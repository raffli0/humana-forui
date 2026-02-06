import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/ui/profile_page.dart';
import 'candidate_home_page.dart';
import 'job_list_page.dart';

class CandidateNavigation extends StatefulWidget {
  const CandidateNavigation({super.key});

  @override
  State<CandidateNavigation> createState() => _CandidateNavigationState();
}

class _CandidateNavigationState extends State<CandidateNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      CandidateHomePage(onSeeAll: () => setState(() => _currentIndex = 1)),
      const JobListPage(),
      const ProfilePage(showBackButton: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: FBottomNavigationBar(
              index: _currentIndex,
              onChange: (index) => setState(() => _currentIndex = index),
              children: const [
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.house),
                  label: Text("Beranda"),
                ),
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.briefcase),
                  label: Text("Lowongan"),
                ),
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.user),
                  label: Text("Profil"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
