package com.moneytracker.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class QuickActionWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Slot 1
                val cat1 = widgetData.getString("fav_cat_1", "Makan") ?: "Makan"
                setTextViewText(R.id.widget_text_1, cat1)
                setOnClickPendingIntent(R.id.widget_button_1, 
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("expenseTracker://add?category=$cat1")))

                // Slot 2
                val cat2 = widgetData.getString("fav_cat_2", "Transport") ?: "Transport"
                setTextViewText(R.id.widget_text_2, cat2)
                setOnClickPendingIntent(R.id.widget_button_2, 
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("expenseTracker://add?category=$cat2")))

                // Slot 3
                val cat3 = widgetData.getString("fav_cat_3", "Belanja") ?: "Belanja"
                setTextViewText(R.id.widget_text_3, cat3)
                setOnClickPendingIntent(R.id.widget_button_3, 
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("expenseTracker://add?category=$cat3")))

                // Slot 4 (Static)
                setOnClickPendingIntent(R.id.widget_button_4, 
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("expenseTracker://add?category=empty")))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
