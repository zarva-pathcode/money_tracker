import 'package:hive/hive.dart';

part 'budget_item.g.dart';

@HiveType(typeId: 2)
class BudgetItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final double limitAmount;

  @HiveField(3, defaultValue: 80.0)
  final double threshold;

  @HiveField(4, defaultValue: 'monthly')
  final String granularity; // 'daily', 'weekly', 'monthly'

  BudgetItem({
    required this.id,
    required this.category,
    required this.limitAmount,
    this.threshold = 80.0,
    this.granularity = 'monthly',
  }) : assert(threshold >= 50 && threshold <= 100, 'threshold must be 50-100');
}
