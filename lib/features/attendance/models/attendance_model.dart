class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInLocation;
  final String? checkOutLocation;
  final String checkInImageUrl;
  final String? checkOutImageUrl;
  final String? companyId;
  final String status; // On Time, Late, etc.
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>>? breaks;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.companyId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLocation,
    this.checkOutLocation,
    required this.checkInImageUrl,
    this.checkOutImageUrl,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.breaks,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json, String docId) {
    // Helper to combine date string and time string into DateTime
    DateTime parseDateTime(String dateStr, String? timeStr) {
      if (timeStr == null) {
        return DateTime.parse(dateStr); // Fallback to just date
      }

      // timeStr might be "09:00:00" or "09:00:00+00"
      final timeParts = timeStr.split('+')[0].split(':');
      final date = DateTime.parse(dateStr);

      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.tryParse(timeParts[2].split('.')[0]) ?? 0,
      );
    }

    final dateStr =
        json['date'] as String? ??
        DateTime.now().toIso8601String().split('T')[0];

    return AttendanceModel(
      id: docId,
      userId: json['employee_id'] ?? '',
      userName: json['employee_name'] ?? 'Unknown',
      companyId: json['company_id'],
      checkInTime: parseDateTime(dateStr, json['check_in']),
      checkOutTime: json['check_out'] != null
          ? parseDateTime(dateStr, json['check_out'])
          : null,
      checkInLocation:
          json['location']?['address'] ??
          json['location']?['check_in_address'] ??
          '',
      checkOutLocation: json['location']?['check_out_address'],
      checkInImageUrl: json['check_in_image'] ?? '',
      checkOutImageUrl: json['check_out_image'],
      latitude:
          (json['location']?['lat'] as num?)?.toDouble() ??
          (json['location']?['latitude'] as num?)?.toDouble() ??
          0.0,
      longitude:
          (json['location']?['lng'] as num?)?.toDouble() ??
          (json['location']?['longitude'] as num?)?.toDouble() ??
          0.0,
      status: json['status'] ?? 'pending',
      breaks: json['breaks'] != null
          ? List<Map<String, dynamic>>.from(json['breaks'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Helper to format Time
    String formatTime(DateTime dt) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    }

    // Helper to format Date
    String formatDate(DateTime dt) {
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }

    return {
      'employee_id': userId,
      'employee_name': userName,
      'company_id': companyId,
      'date': formatDate(checkInTime),
      'check_in': formatTime(checkInTime),
      'check_out': checkOutTime != null ? formatTime(checkOutTime!) : null,
      'status': status,
      'check_in_image': checkInImageUrl,
      'check_out_image': checkOutImageUrl,
      'location': {
        'address': checkInLocation,
        'check_in_address': checkInLocation,
        'check_out_address': checkOutLocation,
        'lat': latitude,
        'lng': longitude,
      },
    };
  }
}
