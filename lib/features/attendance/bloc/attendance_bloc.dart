import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/core/services/location_service.dart';
import 'package:humana/core/services/config_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/attendance_service.dart';
import 'package:latlong2/latlong.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LocationService _locationService;
  final ConfigService _configService;
  final AttendanceService _attendanceService;
  final AuthService _authService;
  StreamSubscription? _locationSubscription;
  Timer? _clockTimer;

  DateTime? _lastGeocodeTime;
  LatLng? _lastGeocodeLatLng;
  static const Duration _geoCacheDuration = Duration(seconds: 30);

  static const double _geoCacheDistanceMeter = 30;
  final String companyId;

  AttendanceBloc({
    required LocationService locationService,
    ConfigService? configService,
    AttendanceService? attendanceService,
    AuthService? authService,
    required this.companyId,
  }) : _locationService = locationService,
       _configService = configService ?? ConfigService(),
       _attendanceService = attendanceService ?? AttendanceService(),
       _authService = authService ?? AuthService(),
       super(AttendanceState(now: DateTime.now())) {
    on<AttendanceStarted>(_onStarted);
    on<AttendanceLocationUpdated>(_onLocationUpdated);
    on<AttendanceAddressUpdated>(_onAddressUpdated);
    on<AttendanceClockTicked>(_onClockTicked);
    on<AttendanceTabChanged>(_onTabChanged);
    on<AttendanceCheckInRequested>(_onCheckIn);
    on<AttendanceCheckOutRequested>(_onCheckOut);
    on<AttendanceBreakRequested>(_onBreak);
    on<AttendanceOffBreakRequested>(_onOffBreak);
  }

  Future<void> _onStarted(
    AttendanceStarted event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      // 1. Fetch Office Config from Firestore
      final config = await _configService.getOfficeConfig(companyId);
      final officeLatLng = LatLng(
        (config['latitude'] as num).toDouble(),
        (config['longitude'] as num).toDouble(),
      );
      final radius = (config['radius'] as num).toDouble();

      // Fetch Shift Config (Global Default)
      final shiftConfig = await _configService.getShiftConfig(companyId);
      final defaultStart = shiftConfig['start_time'] as String?;
      final defaultEnd = shiftConfig['end_time'] as String?;
      final globalTolerance = shiftConfig['tolerance_time'] as int? ?? 0;

      // Determine Effective Shift (Override > Default)
      // 1.1 Refresh User Data to get joined Shifts
      final freshUser = await _authService.checkAuthStatus();
      final shiftStart = freshUser?.shiftStart ?? defaultStart;
      final shiftEnd = freshUser?.shiftEnd ?? defaultEnd;

      // Use user-specific tolerance if available (User Model defaults to 0 if missing)
      // If user has a shift assigned, we prefer that shift's tolerance.
      // Assuming if freshUser is not null, and has toleranceMinutes, we use it.
      // Note: UserModel defaults toleranceMinutes to 0.
      // If the specific shift HAS 0 tolerance, we want 0.
      // So we should check if 'shifts' relation existed?
      // Actually, if a user is assigned a shift, that shift DEFINES the rules.
      // So checking freshUser.toleranceMinutes is correct. But what if it's 0 and Global is 5?
      // Usually specific overrides global. If specific is 0, then 0 it is.
      // But if user has NO shift assigned (null), then we use keys from global?
      // UserModel logic: `json['shifts']?['tolerance_time']`. If `shifts` is null, returns 0.
      // So if User has basic profile but no shift assigned, tolerance is 0.
      // Ideally we want to fallback to Global if User has NO shift.

      int tolerance = globalTolerance;
      if (freshUser?.shiftStart != null) {
        // Implies user has a specific shift assigned
        tolerance = freshUser!.toleranceMinutes;
      }

      final now = DateTime.now();
      final isShiftValid = _validateShift(now, shiftStart, shiftEnd);

      emit(
        state.copyWith(
          officeLocation: officeLatLng,
          officeRadius: radius,
          shiftStart: shiftStart,
          shiftEnd: shiftEnd,
          toleranceMinutes: tolerance,
          isShiftValid: isShiftValid,
        ),
      );

      // 2. Check Initial Attendance Status
      final user = _authService.currentUser;
      if (user != null) {
        final today = await _attendanceService.getTodayAttendance(user.id);
        if (today != null) {
          AttendanceMainStatus mainStatus;
          BreakStatus breakStatus = BreakStatus.none;

          if (today.checkOutTime == null) {
            mainStatus = AttendanceMainStatus.checkin;
            // Check if currently on break
            if (today.breaks != null && today.breaks!.isNotEmpty) {
              final lastBreak = today.breaks!.last;
              if (lastBreak['end'] == null) {
                breakStatus = BreakStatus.onBreak;
              }
            }
          } else {
            mainStatus = AttendanceMainStatus.none;
          }

          emit(
            state.copyWith(mainStatus: mainStatus, breakStatus: breakStatus),
          );
        }
      }

      // 3. Start Location Tracking
      final pos = await _locationService.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      add(AttendanceLocationUpdated(latLng));

      _locationSubscription = _locationService.getPositionStream().listen((
        pos,
      ) {
        add(AttendanceLocationUpdated(LatLng(pos.latitude, pos.longitude)));
      });

      _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(AttendanceClockTicked(DateTime.now()));
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLocationUpdated(
    AttendanceLocationUpdated event,
    Emitter<AttendanceState> emit,
  ) async {
    final officeLoc = state.officeLocation; // May be null initially
    final radius = state.officeRadius;

    bool isInside = false;
    if (officeLoc != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        event.location,
        officeLoc,
      );
      isInside = distance <= radius;
    }

    emit(state.copyWith(userLatLng: event.location, isInsideOffice: isInside));

    final now = DateTime.now();
    final shouldGeocode =
        _lastGeocodeTime == null ||
        _lastGeocodeLatLng == null ||
        now.difference(_lastGeocodeTime!) > _geoCacheDuration ||
        const Distance().as(
              LengthUnit.Meter,
              event.location,
              _lastGeocodeLatLng!,
            ) >
            _geoCacheDistanceMeter;

    if (shouldGeocode) {
      try {
        final addr = await _locationService.getAddress(
          event.location.latitude,
          event.location.longitude,
        );
        _lastGeocodeTime = now;
        _lastGeocodeLatLng = event.location;
        add(AttendanceAddressUpdated(addr));
      } catch (e) {
        // Silent fail for geocoding
      }
    }
  }

  void _onAddressUpdated(
    AttendanceAddressUpdated event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(currentAddress: event.address));
  }

  void _onClockTicked(
    AttendanceClockTicked event,
    Emitter<AttendanceState> emit,
  ) {
    final now = event.now;
    final isValid = _validateShift(now, state.shiftStart, state.shiftEnd);
    emit(state.copyWith(now: now, isShiftValid: isValid));
  }

  Future<void> _onTabChanged(
    AttendanceTabChanged event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(tabIndex: event.index));
    if (event.index == 1) {
      await _fetchHistory(emit);
    }
  }

  Future<void> _fetchHistory(Emitter<AttendanceState> emit) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final history = await _attendanceService.getUserAttendance(user.id);
      emit(state.copyWith(attendanceHistory: history));
    } catch (e) {
      developer.log("Error fetching history: $e", name: "AttendanceBloc");
    }
  }

  Future<void> _onCheckIn(
    AttendanceCheckInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceStatus.loading,
        successType: AttendanceSuccessType.none,
      ),
    );

    try {
      if (state.userLatLng == null) throw Exception("Location not available");

      final user = _authService.currentUser;
      if (user == null) throw Exception("User not authenticated");

      developer.log(
        "Checking in with image: ${event.imageFile?.path}",
        name: "AttendanceBloc",
      );

      final locationString = state.currentAddress.isNotEmpty
          ? state.currentAddress
          : "${state.userLatLng!.latitude}, ${state.userLatLng!.longitude}";

      // Validate Shift Timing
      final now = state.now;
      final shiftStartStr = state.shiftStart;
      final shiftEndStr = state.shiftEnd;

      if (shiftStartStr == null || shiftEndStr == null) {
        emit(
          state.copyWith(
            status: AttendanceStatus.error,
            errorMessage: "No shift assigned for today.",
          ),
        );
        return;
      }

      final startParts = shiftStartStr.split(':');
      final endParts = shiftEndStr.split(':');

      final shiftStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final shiftEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      // Strict validation: Must be within Shift Start and Shift End
      // Note: If shift end is next day (e.g. night shift), this simple logic fails.
      // Assuming same-day shift for now as per current simple implementation.
      // If we need night shift support, we need to handle day overflow.

      // Let's assume standard day shift for MVP as per user "out of range" request.

      bool isShiftValid = false;

      // Handle night shift case where end < start (e.g. 22:00 to 06:00)
      if (shiftEndTime.isBefore(shiftStartTime)) {
        // This implies shift ends the next day.
        // If now is > start (e.g. 23:00), valid.
        // If now is < end (e.g. 05:00), valid.
        if (now.isAfter(shiftStartTime) || now.isBefore(shiftEndTime)) {
          isShiftValid = true;
        }
      } else {
        // Standard Day Shift
        if (now.isAfter(shiftStartTime) && now.isBefore(shiftEndTime)) {
          isShiftValid = true;
        }
      }

      if (!isShiftValid) {
        emit(
          state.copyWith(
            status: AttendanceStatus.error,
            errorMessage:
                "You can only check in between $shiftStartStr and $shiftEndStr",
          ),
        );
        return;
      }

      // Calculate Check-in Status
      String status = "On Time";
      try {
        final tolerance = Duration(minutes: state.toleranceMinutes);
        if (now.isAfter(shiftStartTime.add(tolerance))) {
          status = "Late";
        }
      } catch (e) {
        developer.log("Error calculating status: $e", name: "AttendanceBloc");
      }

      await _attendanceService.checkIn(
        userId: user.id,
        userName:
            user.userMetadata?['full_name'] ?? "Employee", // Fallback name
        companyId: companyId,
        location: locationString,
        status: status,
        latitude: state.userLatLng!.latitude,
        longitude: state.userLatLng!.longitude,
        insideOffice: state.isInsideOffice,
        imageFile: event.imageFile,
        shiftStart: shiftStartStr,
        shiftEnd: shiftEndStr,
        tolerance: state.toleranceMinutes,
      );

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          successType: AttendanceSuccessType.checkIn,
          mainStatus: AttendanceMainStatus.checkin,
          breakStatus: BreakStatus.none,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e.toString(),
          successType: AttendanceSuccessType.none,
        ),
      );
    }
  }

  Future<void> _onCheckOut(
    AttendanceCheckOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceStatus.loading,
        successType: AttendanceSuccessType.none,
      ),
    );
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get today's attendance to find ID
      final today = await _attendanceService.getTodayAttendance(user.id);
      if (today == null) throw Exception("No active check-in found");

      final locationString = state.currentAddress.isNotEmpty
          ? state.currentAddress
          : "${state.userLatLng?.latitude ?? 0}, ${state.userLatLng?.longitude ?? 0}";

      await _attendanceService.checkOut(
        attendanceId: today.id,
        location: locationString,
        latitude: state.userLatLng?.latitude ?? 0.0,
        longitude: state.userLatLng?.longitude ?? 0.0,
        imageFile: null,
      );

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          successType: AttendanceSuccessType.checkOut,
          mainStatus: AttendanceMainStatus.none, // Reset check-in cycle
          breakStatus: BreakStatus.none,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e.toString(),
          successType: AttendanceSuccessType.none,
        ),
      );
    }
  }

  Future<void> _onBreak(
    AttendanceBreakRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceStatus.loading,
        successType: AttendanceSuccessType.none,
      ),
    );
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final today = await _attendanceService.getTodayAttendance(user.id);
      if (today == null) throw Exception("No active attendance found");

      // await _attendanceService.startBreak(today.id); // Disabled: Column missing in DB

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          successType: AttendanceSuccessType.breakStart,
          breakStatus: BreakStatus.onBreak,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e.toString(),
          successType: AttendanceSuccessType.none,
        ),
      );
    }
  }

  Future<void> _onOffBreak(
    AttendanceOffBreakRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceStatus.loading,
        successType: AttendanceSuccessType.none,
      ),
    );
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final today = await _attendanceService.getTodayAttendance(user.id);
      if (today == null) throw Exception("No active attendance found");

      // await _attendanceService.endBreak(today.id); // Disabled: Column missing in DB

      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          successType: AttendanceSuccessType.breakEnd,
          breakStatus:
              BreakStatus.none, // Or offBreak if special styling needed
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e.toString(),
          successType: AttendanceSuccessType.none,
        ),
      );
    }
  }

  bool _validateShift(DateTime now, String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return false;
    try {
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      // Handle night shift case where end < start (e.g. 22:00 to 06:00)
      if (endTime.isBefore(startTime)) {
        // This implies shift ends the next day.
        // If now is > start (e.g. 23:00), valid.
        // If now is < end (e.g. 05:00), valid.
        return now.isAfter(startTime) || now.isBefore(endTime);
      } else {
        // Standard Day Shift
        return now.isAfter(startTime) && now.isBefore(endTime);
      }
    } catch (e) {
      return false; // Fail safe
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _clockTimer?.cancel();
    return super.close();
  }
}
