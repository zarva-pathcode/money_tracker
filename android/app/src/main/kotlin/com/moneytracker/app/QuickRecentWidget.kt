package com.moneytracker.app

import android.appwidget.AppWidgetManager
import android.content.Context
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

            // Transactions
            val txsJson = widgetData.getString("recent_transactions", "[]") ?: "[]"
            val txs = try { JSONArray(txsJson) } catch (_: Exception) { JSONArray() }
            val totalPages = maxOf(1, (txs.length() + 4) / 5)
            var currentPage = try {
                widgetData.getString("recent_page", "0")?.toIntOrNull() ?: 0
            } catch (_: Exception) { 0 }
            if (currentPage >= totalPages) currentPage = totalPages - 1
            if (currentPage < 0) currentPage = 0

            val startIndex = currentPage * 5
            for (i in 0 until 5) {
                val emojiId = context.resources.getIdentifier(
                    "widget_recent_tx_${i + 1}_emoji", "id", context.packageName)
                val titleId = context.resources.getIdentifier(
                    "widget_recent_tx_${i + 1}_title", "id", context.packageName)
                val amountId = context.resources.getIdentifier(
                    "widget_recent_tx_${i + 1}_amount", "id", context.packageName)
                val rowId = context.resources.getIdentifier(
                    "widget_recent_tx_${i + 1}", "id", context.packageName)

                val txIndex = startIndex + i
                if (txIndex < txs.length()) {
                    val tx = txs.getJSONObject(txIndex)
                    views.setTextViewText(emojiId, tx.optString("emoji", ""))
                    views.setTextViewText(titleId, tx.optString("title", ""))
                    views.setTextViewText(amountId, "Rp${tx.optString("amount", "0")}")
                    val colorHex = tx.optString("color", "#EF5350")
                    try {
                        views.setTextColor(emojiId, Color.parseColor(colorHex))
                    } catch (_: Exception) {}
                    views.setViewVisibility(rowId, View.VISIBLE)
                } else {
                    views.setTextViewText(emojiId, "")
                    views.setTextViewText(titleId, "Tidak ada")
                    views.setTextViewText(amountId, "")
                }
            }

            // Pagination
            views.setTextViewText(R.id.widget_recent_page, "${currentPage + 1}/$totalPages")

            // Prev button
            views.setViewVisibility(R.id.widget_recent_btn_prev, View.VISIBLE)
            val prevPage = currentPage - 1
            if (prevPage >= 0) {
                views.setOnClickPendingIntent(R.id.widget_recent_btn_prev,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java,
                        Uri.parse("expenseTracker://widget?action=page&value=$prevPage")))
            } else {
                views.setOnClickPendingIntent(R.id.widget_recent_btn_prev, null)
                views.setViewVisibility(R.id.widget_recent_btn_prev, View.INVISIBLE)
            }

            // Next button
            views.setViewVisibility(R.id.widget_recent_btn_next, View.VISIBLE)
            val nextPage = currentPage + 1
            if (nextPage < totalPages) {
                views.setOnClickPendingIntent(R.id.widget_recent_btn_next,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java,
                        Uri.parse("expenseTracker://widget?action=page&value=$nextPage")))
            } else {
                views.setOnClickPendingIntent(R.id.widget_recent_btn_next, null)
                views.setViewVisibility(R.id.widget_recent_btn_next, View.INVISIBLE)
            }

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
