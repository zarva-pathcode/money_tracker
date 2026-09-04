package com.moneytracker.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class QuickRecentWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return QuickRecentWidgetFactory(this.applicationContext, intent)
    }
}

class QuickRecentWidgetFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var txs = JSONArray()

    override fun onCreate() {
        // Init
    }

    override fun onDataSetChanged() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val txsJson = widgetData.getString("recent_transactions", "[]") ?: "[]"
        txs = try {
            JSONArray(txsJson)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    override fun onDestroy() {
        // Cleanup
    }

    override fun getCount(): Int {
        // Max 10 items
        return minOf(txs.length(), 10)
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_recent_list_item)
        
        if (position < txs.length()) {
            val tx = txs.getJSONObject(position)
            views.setTextViewText(R.id.item_emoji, tx.optString("emoji", ""))
            views.setTextViewText(R.id.item_title, tx.optString("title", ""))
            views.setTextViewText(R.id.item_amount, "Rp${tx.optString("amount", "0")}")
            
            val colorHex = tx.optString("color", "#EF5350")
            try {
                views.setTextColor(R.id.item_emoji, Color.parseColor(colorHex))
            } catch (_: Exception) {}
        }
        
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
