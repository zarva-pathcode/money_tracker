import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';

class WidgetProvider with ChangeNotifier {
  final Box _box = Hive.box('settings');
  
  late List<String> favoriteCategories;

  WidgetProvider() {
    _loadFavorites();
  }

  void _loadFavorites() {
    favoriteCategories = [
      _box.get('fav_cat_1', defaultValue: 'Makanan'),
      _box.get('fav_cat_2', defaultValue: 'Transportasi'),
      _box.get('fav_cat_3', defaultValue: 'Belanja'),
    ];
  }

  Future<void> updateFavorite(int index, String category) async {
    favoriteCategories[index] = category;
    await _box.put('fav_cat_${index + 1}', category);
    
    // Sync to Home Screen Widget
    await _syncToWidget();
    
    notifyListeners();
  }

  Future<void> _syncToWidget() async {
    try {
      await HomeWidget.saveWidgetData('fav_cat_1', favoriteCategories[0]);
      await HomeWidget.saveWidgetData('fav_cat_2', favoriteCategories[1]);
      await HomeWidget.saveWidgetData('fav_cat_3', favoriteCategories[2]);
      
      // Request update for both Android and iOS
      await HomeWidget.updateWidget(
        name: 'QuickActionWidget', // Nama class di Android
        androidName: 'QuickActionWidget',
        iOSName: 'QuickActionWidget',
      );
    } catch (e) {
      debugPrint("Error syncing widget: $e");
    }
  }

  // Initial sync when app starts
  Future<void> initialSync() async {
    await _syncToWidget();
  }
}
