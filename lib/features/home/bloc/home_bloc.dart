import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../attendance/services/attendance_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AttendanceService _attendanceService;

  HomeBloc({AttendanceService? attendanceService})
    : _attendanceService = attendanceService ?? AttendanceService(),
      super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeBreakToggled>(_onBreakToggled);
  }

  Future<void> _onBreakToggled(
    HomeBreakToggled event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.isStarting) {
        // await _attendanceService.startBreak(event.attendanceId); // Disabled
      } else {
        // await _attendanceService.endBreak(event.attendanceId); // Disabled
      }

      final userId = state.todayAttendance?.userId;
      if (userId != null) {
        add(HomeRefreshRequested(userId));
      }
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final allAttendance = await _attendanceService.getUserAttendance(
        event.userId,
      );

      // Find today's attendance
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayAttendance = allAttendance.where((a) {
        final aDate = a.checkInTime;
        return aDate.year == today.year &&
            aDate.month == today.month &&
            aDate.day == today.day;
      }).firstOrNull;

      emit(
        state.copyWith(
          status: HomeStatus.success,
          todayAttendance: todayAttendance,
          recentActivity: allAttendance.take(5).toList(), // Limit to 5
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(HomeStarted(event.userId));
  }
}
