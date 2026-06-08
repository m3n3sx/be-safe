package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class NearestWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_nearest)
            val has = widgetData.getBoolean("near_has", false)
            if (has) {
                views.setTextViewText(R.id.near_cat, widgetData.getString("near_cat", "Alert"))
                views.setTextColor(R.id.near_cat, Color.parseColor("#FF7A7A"))
                views.setTextViewText(R.id.near_meta, widgetData.getString("near_meta", ""))
            } else {
                views.setTextViewText(R.id.near_cat, "Brak zagrożeń")
                views.setTextColor(R.id.near_cat, Color.parseColor("#6BE332"))
                views.setTextViewText(R.id.near_meta, "Twoja okolica jest bezpieczna")
            }
            views.setOnClickPendingIntent(
                R.id.near_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("besafe://nearest"))
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
