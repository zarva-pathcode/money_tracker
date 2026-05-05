import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

part 'plan_item.g.dart';

@HiveType(typeId: 1)
class PlanItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  int iconCodePoint;

  PlanItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.colorValue,
    required this.iconCodePoint,
  });

  // Helper getters
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }
  
  Color get color => Color(colorValue);
  dynamic get icon => Constants.getPlanIcon(iconCodePoint);
}
