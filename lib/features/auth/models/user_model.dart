import '../../payroll/models/position_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? department;
  final String? employeeId;
  final String? manager;
  final String? companyId;
  final String? employeeCode; // Human readable code
  final String? shiftStart;
  final String? shiftEnd;
  final int toleranceMinutes;
  final String status;
  final String? profilePhotoUrl;
  final double basicSalary;
  final PositionModel? position;
  final String? jobId; // For candidates
  final String? applicationStatus; // For candidates
  final String? jobTitle; // For candidates

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'admin',
    this.phone,
    this.department,
    this.employeeId,
    this.employeeCode,
    this.manager,
    this.companyId,
    this.shiftStart,
    this.shiftEnd,
    this.toleranceMinutes = 0,
    this.status = 'active',
    this.profilePhotoUrl,
    this.basicSalary = 0,
    this.position,
    this.jobId,
    this.applicationStatus,
    this.jobTitle,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return UserModel(
      id: json['id'] ?? '',
      fullName: json['name'] ?? 'Unknown User', // Mapped from 'name'
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee', // Default if missing
      phone: json['phone'],
      department: json['department'],
      employeeId: json['id'], // ID is the employee ID
      employeeCode: json['employee_code'],
      manager: json['manager'],
      companyId: json['company_id'],
      shiftStart: json['shifts']?['start_time'] ?? json['shift_start'],
      shiftEnd: json['shifts']?['end_time'] ?? json['shift_end'],
      toleranceMinutes: parseInt(
        json['shifts']?['tolerance_time'] ??
            json['shifts']?['tolerance_minutes'] ??
            json['tolerance_time'],
      ),
      status: json['status'] ?? 'active',
      profilePhotoUrl: json['avatar'] ?? json['user_image_url'],
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      position: json['positions'] != null
          ? PositionModel.fromJson(json['positions'])
          : null,
      jobId: json['job_id'],
      applicationStatus: json['application_status'] ?? json['status'],
      jobTitle: json['recruitments']?['title'] ?? json['job_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName, // Mapped to 'name'
      'email': email,
      'role': role,
      'phone': phone,
      'department': department,
      // 'employee_id': employeeId, // usually same as id in this schema
      'employee_code': employeeCode,
      'manager': manager,
      'company_id': companyId,
      'shift_start': shiftStart,
      'shift_end': shiftEnd,
      'tolerance_time': toleranceMinutes,
      'status': status,
      'avatar': profilePhotoUrl,
      'job_id': jobId,
      'application_status': applicationStatus,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? department,
    String? employeeId,
    String? employeeCode,
    String? manager,
    String? companyId,
    String? shiftStart,
    String? shiftEnd,
    int? toleranceMinutes,
    String? status,
    String? profilePhotoUrl,
    String? jobId,
    String? applicationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      manager: manager ?? this.manager,
      companyId: companyId ?? this.companyId,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
      status: status ?? this.status,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      jobId: jobId ?? this.jobId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
    );
  }
}
