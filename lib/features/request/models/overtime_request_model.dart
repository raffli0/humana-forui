class OvertimeRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String companyId;
  final String type = 'Overtime';
  final DateTime date;
  final int durationMinutes; // e.g. 120 for 2 hours
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? adminNote;

  OvertimeRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.companyId = 'default_company',
    required this.date,
    required this.durationMinutes,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.adminNote,
  });

  factory OvertimeRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return OvertimeRequestModel(
      id: id,
      userId: map['employee_id'] ?? '',
      userName: map['employee_name'] ?? 'Unknown',
      companyId: map['company_id'] ?? 'default_company',
      date: DateTime.parse(map['overtime_date']),
      durationMinutes: map['duration_minutes'] ?? 0,
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      adminNote: map['admin_note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': userId,
      'employee_name': userName,
      'company_id': companyId,
      'overtime_date': date.toIso8601String().split('T')[0],
      'duration_minutes': durationMinutes,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
