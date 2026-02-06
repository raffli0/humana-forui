class ShiftSwapRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String companyId;
  final String type = 'Shift Swap';
  final DateTime myShiftDate;
  final String targetUserId; // Optional: specific person to swap with
  final String targetUserName;
  final DateTime targetShiftDate;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? adminNote;

  ShiftSwapRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.companyId = 'default_company',
    required this.myShiftDate,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetShiftDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.adminNote,
  });

  factory ShiftSwapRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ShiftSwapRequestModel(
      id: id,
      requesterId: map['requester_id'] ?? '',
      requesterName: map['requester_name'] ?? 'Unknown',
      companyId: map['company_id'] ?? 'default_company',
      myShiftDate: DateTime.parse(map['my_shift_date']),
      targetUserId: map['target_user_id'] ?? '',
      targetUserName: map['target_user_name'] ?? 'Unknown',
      targetShiftDate: DateTime.parse(map['target_shift_date']),
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
      'requester_id': requesterId,
      'requester_name': requesterName,
      'company_id': companyId,
      'my_shift_date': myShiftDate.toIso8601String().split('T')[0],
      'target_user_id': targetUserId,
      'target_user_name': targetUserName,
      'target_shift_date': targetShiftDate.toIso8601String().split('T')[0],
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
