class LeaveRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userImageUrl;
  final String companyId;
  final String type;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final String? adminNote;
  final DateTime? updatedAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    this.companyId = 'default_company',
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.updatedAt,
  });

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return LeaveRequestModel(
      id: id,
      userId: map['employee_id'] ?? '',
      userName: map['employee_name'] ?? 'Unknown',
      userImageUrl: '', // Column missing in DB
      companyId: map['company_id'] ?? 'default_company',
      type: map['type'] ?? 'General',
      reason: map['reason'] ?? '',
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(
        map['request_date'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_id': userId,
      'employee_name': userName,
      'company_id': companyId,
      'type': type,
      'reason': reason,
      'start_date': startDate.toIso8601String().split('T')[0], // Use YYYY-MM-DD
      'end_date': endDate.toIso8601String().split('T')[0],
      'status': status,
      'days': endDate.difference(startDate).inDays + 1,
      'request_date': createdAt.toIso8601String().split('T')[0],
    };
  }
}
