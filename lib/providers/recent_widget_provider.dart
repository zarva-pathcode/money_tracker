import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class RecentWidgetProvider {
  static const _channel = 'QuickRecentWidget';

  static Future<void> sync({
    required double balance,
    required double periodExpenses,
    required String balanceLabel,
    required List<Expense> recentExpenses,
  }) async {
    try {
      final txs = recentExpenses.take(15).map((e) {
        final style = Constants.getCategoryStyle(e.category);
        return {
          'emoji': Constants.getCategoryEmoji(e.category),
          'color': Constants.colorHex(style['color'] as Color),
          'title': e.title.isNotEmpty ? e.title : e.category,
          'amount': e.amount.toInt().toString(),
        };
      }).toList();

      await HomeWidget.saveWidgetData('recent_balance', balance.toInt().toString());
      await HomeWidget.saveWidgetData('recent_expenses', periodExpenses.toInt().toString());
      await HomeWidget.saveWidgetData('recent_label', balanceLabel);
      await HomeWidget.saveWidgetData('recent_transactions', jsonEncode(txs));
      await HomeWidget.saveWidgetData('recent_page', '0');

      await HomeWidget.updateWidget(
        name: _channel,
        androidName: _channel,
        iOSName: _channel,
      );
    } catch (e) {
      debugPrint("Error syncing recent widget: $e");
    }
  }
}
