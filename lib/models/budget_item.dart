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

  BudgetItem({
    required this.id,
    required this.category,
    required this.limitAmount,
  });
}
