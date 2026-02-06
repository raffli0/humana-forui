class PositionModel {
  final String id;
  final String name;
  final double baseSalary;
  final double transportAllowance;
  final double mealAllowance;

  PositionModel({
    required this.id,
    required this.name,
    required this.baseSalary,
    required this.transportAllowance,
    required this.mealAllowance,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      baseSalary: (json['base_salary'] ?? 0).toDouble(),
      transportAllowance: (json['transport_allowance'] ?? 0).toDouble(),
      mealAllowance: (json['meal_allowance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'base_salary': baseSalary,
      'transport_allowance': transportAllowance,
      'meal_allowance': mealAllowance,
    };
  }
}
