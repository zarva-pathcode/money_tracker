package com.moneytracker.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray

class QuickRecentWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_recent_layout)

            // Header
            val balance = widgetData.getString("recent_balance", "0") ?: "0"
            val expenses = widgetData.getString("recent_expenses", "0") ?: "0"
            views.setTextViewText(R.id.widget_recent_balance, "Rp$balance")
            views.setTextViewText(R.id.widget_recent_expenses, "Rp$expenses")

            // Set up the ListView
            val intent = Intent(context, QuickRecentWidgetService::class.java)
            // Add appWidgetId to intent to differentiate instances if needed
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            intent.data = Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME))
            views.setRemoteAdapter(R.id.widget_recent_list, intent)
            views.setEmptyView(R.id.widget_recent_list, R.id.widget_recent_list) // This is optional if we have empty view

            // Voice button
            views.setOnClickPendingIntent(R.id.widget_recent_btn_voice,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("expenseTracker://add?voice=true")))

            // Add button
            views.setOnClickPendingIntent(R.id.widget_recent_btn_add,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("expenseTracker://add?category=empty")))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
