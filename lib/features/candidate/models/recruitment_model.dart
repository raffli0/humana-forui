class RecruitmentModel {
  final String id;
  final String title;
  final String department;
  final String type; // e.g., 'Full-time', 'Contract'
  final String location;
  final String salaryRange;
  final String description;
  final String requirements;
  final String status; // 'active', 'closed'
  final DateTime createdAt;
  final String companyName;

  RecruitmentModel({
    required this.id,
    required this.title,
    required this.department,
    required this.type,
    required this.location,
    required this.salaryRange,
    required this.description,
    required this.requirements,
    required this.status,
    required this.createdAt,
    required this.companyName,
  });

  factory RecruitmentModel.fromJson(Map<String, dynamic> json) {
    return RecruitmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      department: json['department_name'] ?? json['department'] ?? '',
      type: json['employment_type'] ?? 'Full-time',
      location: json['location'] ?? 'On-site',
      salaryRange: json['salary_range'] ?? 'Competitive',
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
      status: json['status'] ?? 'active',
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      companyName: json['companies'] != null && json['companies'] is Map
          ? (json['companies']['name'] ?? 'Unknown Company')
          : (json['company_name'] ?? 'Unknown Company'),
    );
  }
}
