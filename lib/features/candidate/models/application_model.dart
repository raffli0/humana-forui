class ApplicationModel {
  final String id;
  final String jobId;
  final String candidateId;
  final String status; // 'New', 'Reviewed', 'Accepted', 'Rejected'
  final DateTime appliedAt;
  final String? resumeUrl;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.candidateId,
    required this.status,
    required this.appliedAt,
    this.resumeUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      candidateId: json['id'] as String, // candidate id is the primary key
      status: json['status'] ?? 'New',
      appliedAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      resumeUrl: json['resume_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'status': status,
      'resume_url': resumeUrl,
    };
  }
}
