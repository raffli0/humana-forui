import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/services.dart';
import 'package:humana/core/theme/app_colors.dart';

import '../../home/ui/home_page.dart';
import '../../attendance/ui/attendance_page.dart';
import '../../attendance/ui/attendance_history_page.dart';
import '../../request/ui/request_page.dart';
import '../../payroll/ui/payroll_page.dart';

class MainRootPage extends StatefulWidget {
  const MainRootPage({super.key});

  @override
  State<MainRootPage> createState() => _MainRootPageState();
}

class _MainRootPageState extends State<MainRootPage> {
  int index = 0;

  final pages = const [
    HomePage(),
    AttendancePage(),
    RequestsPage(),
    AttendanceHistoryPage(),
    PayrollPage(),
  ];

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
        body: pages[index],
        bottomNavigationBar: _buildBottomNav(colors, isDark),
      ),
    );
  }

  Widget _buildBottomNav(AppColors colors, bool isDark) {
    return Container(
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
          index: index,
          onChange: (index) => setState(() => this.index = index),
          children: const [
            FBottomNavigationBarItem(
              icon: Icon(FIcons.house),
              label: Text("Home"),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.calendar),
              label: Text("Attendance"),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.plus),
              label: Text("Request"),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.clock),
              label: Text("History"),
            ),
            FBottomNavigationBarItem(
              icon: Icon(FIcons.banknote),
              label: Text("Payroll"),
            ),
          ],
        ),
      ),
    );
  }
}
