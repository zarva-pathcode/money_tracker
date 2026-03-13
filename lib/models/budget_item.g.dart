// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetItemAdapter extends TypeAdapter<BudgetItem> {
  @override
  final int typeId = 2;

  @override
  BudgetItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetItem(
      id: fields[0] as String,
      category: fields[1] as String,
      limitAmount: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.limitAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
