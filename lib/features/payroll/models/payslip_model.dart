class PayslipModel {
  final String id;
  final String period; // e.g., "January 2024"
  final DateTime paymentDate;
  final double basicSalary;
  final double positionAllowance;
  final double transportAllowance;
  final double mealAllowance;
  final double bpjsHealthAllowance;
  final double bpjsLaborAllowance;
  final double overtime;
  final double bonus;

  final double bpjsHealthDeduction;
  final double bpjsLaborDeduction;
  final double taxDeduction;
  final double loanDeduction;

  final double otherAllowances; // Keep generic for older/other data
  final double deductions; // Keep generic sum or miscellaneous
  final double netSalary;
  final String status;
  final String currency;

  // Employee Details
  final String nik;
  final String npwp;
  final String employmentStatus;

  const PayslipModel({
    required this.id,
    required this.period,
    required this.paymentDate,
    required this.basicSalary,
    this.positionAllowance = 0.0,
    this.transportAllowance = 0.0,
    this.mealAllowance = 0.0,
    this.bpjsHealthAllowance = 0.0,
    this.bpjsLaborAllowance = 0.0,
    this.overtime = 0.0,
    this.bonus = 0.0,
    this.bpjsHealthDeduction = 0.0,
    this.bpjsLaborDeduction = 0.0,
    this.taxDeduction = 0.0,
    this.loanDeduction = 0.0,
    this.otherAllowances = 0.0,
    this.deductions = 0.0,
    required this.netSalary,
    required this.status,
    this.currency = "IDR",
    this.nik = '',
    this.npwp = '',
    this.employmentStatus = '',
  });

  factory PayslipModel.fromJson(Map<String, dynamic> map, String id) {
    return PayslipModel(
      id: id,
      period: map['period'] ?? '',
      paymentDate:
          DateTime.tryParse(map['payment_date'] ?? '') ?? DateTime.now(),
      basicSalary: (map['basic_salary'] as num?)?.toDouble() ?? 0.0,
      positionAllowance: (map['position_allowance'] as num?)?.toDouble() ?? 0.0,
      transportAllowance:
          (map['transport_allowance'] as num?)?.toDouble() ?? 0.0,
      mealAllowance: (map['meal_allowance'] as num?)?.toDouble() ?? 0.0,
      bpjsHealthAllowance:
          (map['bpjs_health_allowance'] as num?)?.toDouble() ?? 0.0,
      bpjsLaborAllowance:
          (map['bpjs_labor_allowance'] as num?)?.toDouble() ?? 0.0,
      overtime: (map['overtime'] as num?)?.toDouble() ?? 0.0,
      bonus: (map['bonus'] as num?)?.toDouble() ?? 0.0,
      bpjsHealthDeduction:
          (map['bpjs_health_deduction'] as num?)?.toDouble() ?? 0.0,
      bpjsLaborDeduction:
          (map['bpjs_labor_deduction'] as num?)?.toDouble() ?? 0.0,
      taxDeduction: (map['tax_deduction'] as num?)?.toDouble() ?? 0.0,
      loanDeduction: (map['loan_deduction'] as num?)?.toDouble() ?? 0.0,
      otherAllowances: (map['other_allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (map['total_deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (map['net_salary'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Draft',
      nik: map['nik'] ?? '',
      npwp: map['npwp'] ?? '',
      employmentStatus: map['employment_status'] ?? '',
    );
  }

  PayslipModel copyWith({
    String? id,
    String? period,
    DateTime? paymentDate,
    double? basicSalary,
    double? positionAllowance,
    double? transportAllowance,
    double? mealAllowance,
    double? bpjsHealthAllowance,
    double? bpjsLaborAllowance,
    double? overtime,
    double? bonus,
    double? bpjsHealthDeduction,
    double? bpjsLaborDeduction,
    double? taxDeduction,
    double? loanDeduction,
    double? otherAllowances,
    double? deductions,
    double? netSalary,
    String? status,
    String? currency,
    String? nik,
    String? npwp,
    String? employmentStatus,
  }) {
    return PayslipModel(
      id: id ?? this.id,
      period: period ?? this.period,
      paymentDate: paymentDate ?? this.paymentDate,
      basicSalary: basicSalary ?? this.basicSalary,
      positionAllowance: positionAllowance ?? this.positionAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      bpjsHealthAllowance: bpjsHealthAllowance ?? this.bpjsHealthAllowance,
      bpjsLaborAllowance: bpjsLaborAllowance ?? this.bpjsLaborAllowance,
      overtime: overtime ?? this.overtime,
      bonus: bonus ?? this.bonus,
      bpjsHealthDeduction: bpjsHealthDeduction ?? this.bpjsHealthDeduction,
      bpjsLaborDeduction: bpjsLaborDeduction ?? this.bpjsLaborDeduction,
      taxDeduction: taxDeduction ?? this.taxDeduction,
      loanDeduction: loanDeduction ?? this.loanDeduction,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      nik: nik ?? this.nik,
      npwp: npwp ?? this.npwp,
      employmentStatus: employmentStatus ?? this.employmentStatus,
    );
  }
}
