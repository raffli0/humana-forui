import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../models/attendance_model.dart';

enum AttendanceStatus { initial, loading, success, error }

enum AttendanceMainStatus { none, checkin, checkout }

enum BreakStatus { none, onBreak, offBreak }

enum AttendanceSuccessType { none, checkIn, checkOut, breakStart, breakEnd }

class AttendanceState extends Equatable {
  final AttendanceStatus status;
  final String? errorMessage;
  final AttendanceSuccessType successType;

  final AttendanceMainStatus mainStatus;
  final BreakStatus breakStatus;
  final LatLng? userLatLng;
  final String currentAddress;
  final bool isInsideOffice;

  final LatLng? officeLocation; // Fetched from config
  final double officeRadius; // Fetched from config

  final DateTime now;
  final int tabIndex;

  final String? shiftStart;
  final String? shiftEnd;
  final int toleranceMinutes;
  final bool isShiftValid;
  final List<AttendanceModel> attendanceHistory;

  const AttendanceState({
    this.status = AttendanceStatus.initial,
    this.errorMessage,
    this.successType = AttendanceSuccessType.none,
    this.mainStatus = AttendanceMainStatus.none,
    this.breakStatus = BreakStatus.none,
    this.userLatLng,
    this.currentAddress = "",
    this.isInsideOffice = false,
    this.officeLocation,
    this.officeRadius = 100.0,
    required this.now,
    this.tabIndex = 0,
    this.shiftStart,
    this.shiftEnd,
    this.toleranceMinutes = 0,
    this.isShiftValid = false,
    this.attendanceHistory = const [],
  });

  AttendanceState copyWith({
    AttendanceStatus? status,
    String? errorMessage,
    AttendanceSuccessType? successType,
    AttendanceMainStatus? mainStatus,
    BreakStatus? breakStatus,
    LatLng? userLatLng,
    String? currentAddress,
    bool? isInsideOffice,
    LatLng? officeLocation,
    double? officeRadius,
    DateTime? now,
    int? tabIndex,
    String? shiftStart,
    String? shiftEnd,
    int? toleranceMinutes,
    bool? isShiftValid,
    List<AttendanceModel>? attendanceHistory,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successType: successType ?? this.successType,
      mainStatus: mainStatus ?? this.mainStatus,
      breakStatus: breakStatus ?? this.breakStatus,
      userLatLng: userLatLng ?? this.userLatLng,
      currentAddress: currentAddress ?? this.currentAddress,
      isInsideOffice: isInsideOffice ?? this.isInsideOffice,
      officeLocation: officeLocation ?? this.officeLocation,
      officeRadius: officeRadius ?? this.officeRadius,
      now: now ?? this.now,
      tabIndex: tabIndex ?? this.tabIndex,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
      isShiftValid: isShiftValid ?? this.isShiftValid,
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successType,
    mainStatus,
    breakStatus,
    userLatLng,
    currentAddress,
    isInsideOffice,
    officeLocation,
    officeRadius,
    now,
    tabIndex,
    shiftStart,
    shiftEnd,
    toleranceMinutes,
    isShiftValid,
    attendanceHistory,
  ];
}
