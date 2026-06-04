package com.moneytracker.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class QuickActionWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Slot 1
                val cat1 = widgetData.getString("fav_cat_1", "Makanan") ?: "Makanan"
                val icon1 = widgetData.getString("fav_cat_1_icon", "\uD83C\uDF7D") ?: "\uD83C\uDF7D"
                val color1 = widgetData.getString("fav_cat_1_color", "#FF8A65") ?: "#FF8A65"
                setTextViewText(R.id.widget_text_1, cat1)
                setTextViewText(R.id.widget_icon_1, icon1)
                setTextColor(R.id.widget_icon_1, Color.parseColor(color1))
                setOnClickPendingIntent(R.id.widget_button_1,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("expenseTracker://add?category=$cat1")))

                // Slot 2
                val cat2 = widgetData.getString("fav_cat_2", "Transportasi") ?: "Transportasi"
                val icon2 = widgetData.getString("fav_cat_2_icon", "\uD83D\uDE97") ?: "\uD83D\uDE97"
                val color2 = widgetData.getString("fav_cat_2_color", "#42A5F5") ?: "#42A5F5"
                setTextViewText(R.id.widget_text_2, cat2)
                setTextViewText(R.id.widget_icon_2, icon2)
                setTextColor(R.id.widget_icon_2, Color.parseColor(color2))
                setOnClickPendingIntent(R.id.widget_button_2,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("expenseTracker://add?category=$cat2")))

                // Slot 3
                val cat3 = widgetData.getString("fav_cat_3", "Belanja") ?: "Belanja"
                val icon3 = widgetData.getString("fav_cat_3_icon", "\uD83D\uDED2") ?: "\uD83D\uDED2"
                val color3 = widgetData.getString("fav_cat_3_color", "#AB47BC") ?: "#AB47BC"
                setTextViewText(R.id.widget_text_3, cat3)
                setTextViewText(R.id.widget_icon_3, icon3)
                setTextColor(R.id.widget_icon_3, Color.parseColor(color3))
                setOnClickPendingIntent(R.id.widget_button_3,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("expenseTracker://add?category=$cat3")))

                // Slot 4 (Static)
                setOnClickPendingIntent(R.id.widget_button_4,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("expenseTracker://add?category=empty")))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
