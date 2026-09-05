import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';

class WidgetProvider with ChangeNotifier {
  final HiveService _hiveService;
  
  late List<String> favoriteCategories;

  WidgetProvider({required HiveService hiveService})
      : _hiveService = hiveService {
    _loadFavorites();
  }

  void _loadFavorites() {
    favoriteCategories = [
      _hiveService.getSetting('fav_cat_1', 'Makanan'),
      _hiveService.getSetting('fav_cat_2', 'Transportasi'),
      _hiveService.getSetting('fav_cat_3', 'Belanja'),
    ];
  }

  Future<void> updateFavorite(int index, String category) async {
    favoriteCategories[index] = category;
    await _hiveService.setSetting('fav_cat_${index + 1}', category);
    
    await _syncToWidget();
    
    notifyListeners();
  }

  Future<void> _syncToWidget() async {
    try {
      for (int i = 0; i < 3; i++) {
        final cat = favoriteCategories[i];
        final style = Constants.getCategoryStyle(cat);
        final color = style.color;
        final suffix = (i + 1).toString();

        await HomeWidget.saveWidgetData('fav_cat_$suffix', cat);
        await HomeWidget.saveWidgetData('fav_cat_${suffix}_icon', Constants.getCategoryEmoji(cat));
        await HomeWidget.saveWidgetData('fav_cat_${suffix}_color',
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}');
      }
      
      await HomeWidget.updateWidget(
        name: 'QuickActionWidget',
        androidName: 'QuickActionWidget',
        iOSName: 'QuickActionWidget',
      );
    } catch (e) {
      debugPrint("Error syncing widget: $e");
    }
  }

  Future<void> initialSync() async {
    await _syncToWidget();
  }
}
