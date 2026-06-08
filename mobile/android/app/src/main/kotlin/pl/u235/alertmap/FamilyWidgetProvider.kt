package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FamilyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_family)
            val online = widgetData.getInt("family_online", 0)
            val total = widgetData.getInt("family_total", 0)
            val sub = widgetData.getString("family_sub", "online teraz")
            views.setTextViewText(R.id.family_count, "$online/$total")
            views.setTextViewText(R.id.family_sub, sub)
            views.setOnClickPendingIntent(
                R.id.family_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("besafe://family"))
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
