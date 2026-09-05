import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/expense.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class RecentWidgetProvider {
  static const _channel = 'QuickRecentWidget';

  static Future<void> sync({
    required double balance,
    required double periodExpenses,
    required String balanceLabel,
    required List<Expense> recentExpenses,
  }) async {
    try {
      final txs = recentExpenses.take(10).map((e) {
        final style = Constants.getCategoryStyle(e.category);
        return {
          'emoji': Constants.getCategoryEmoji(e.category),
          'color': Constants.colorHex(style.color),
          'title': e.title.isNotEmpty ? e.title : e.category,
          'amount': Formatters.formatNumber(e.amount.toInt()),
        };
      }).toList();

      final formattedBalance = Formatters.formatNumber(balance.toInt());
      final formattedExpenses = Formatters.formatNumber(periodExpenses.toInt());

      await HomeWidget.saveWidgetData('recent_balance', formattedBalance);
      await HomeWidget.saveWidgetData('recent_expenses', formattedExpenses);
      await HomeWidget.saveWidgetData('recent_label', balanceLabel);
      await HomeWidget.saveWidgetData('recent_transactions', jsonEncode(txs));

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
