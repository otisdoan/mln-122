class SimulationModel {
  final String id;
  final String userId;
  final double capitalConstant;
  final double capitalVariable;
  final int workers;
  final int machines;
  final int technologyLevel;
  final int workingHours;
  final double profit;
  final double surplusValue;
  final DateTime createdAt;

  const SimulationModel({
    required this.id,
    required this.userId,
    this.capitalConstant = 1200000,
    this.capitalVariable = 450000,
    this.workers = 50,
    this.machines = 12,
    this.technologyLevel = 1,
    this.workingHours = 8,
    this.profit = 0,
    this.surplusValue = 0,
    required this.createdAt,
  });

  factory SimulationModel.fromJson(Map<String, dynamic> json) {
    return SimulationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      capitalConstant: (json['capital_constant'] as num).toDouble(),
      capitalVariable: (json['capital_variable'] as num).toDouble(),
      workers: json['workers'] as int? ?? 50,
      machines: json['machines'] as int? ?? 12,
      technologyLevel: json['technology_level'] as int? ?? 1,
      workingHours: json['working_hours'] as int? ?? 8,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      surplusValue: (json['surplus_value'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'capital_constant': capitalConstant,
      'capital_variable': capitalVariable,
      'workers': workers,
      'machines': machines,
      'technology_level': technologyLevel,
      'working_hours': workingHours,
      'profit': profit,
      'surplus_value': surplusValue,
    };
  }

  SimulationModel copyWith({
    double? capitalConstant,
    double? capitalVariable,
    int? workers,
    int? machines,
    int? technologyLevel,
    int? workingHours,
    double? profit,
    double? surplusValue,
  }) {
    return SimulationModel(
      id: id,
      userId: userId,
      capitalConstant: capitalConstant ?? this.capitalConstant,
      capitalVariable: capitalVariable ?? this.capitalVariable,
      workers: workers ?? this.workers,
      machines: machines ?? this.machines,
      technologyLevel: technologyLevel ?? this.technologyLevel,
      workingHours: workingHours ?? this.workingHours,
      profit: profit ?? this.profit,
      surplusValue: surplusValue ?? this.surplusValue,
      createdAt: createdAt,
    );
  }
}
