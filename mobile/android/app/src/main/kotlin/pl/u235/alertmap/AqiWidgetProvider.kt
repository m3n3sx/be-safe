package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AqiWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_aqi)
            val idx = widgetData.getInt("aqi_index", -1)
            val label = widgetData.getString("aqi_label", "Brak danych")
            val city = widgetData.getString("aqi_city", "Otwórz aplikację po dane")
            val color = when (idx) {
                0 -> "#4CAF50"; 1 -> "#8BC34A"; 2 -> "#FFEB3B"
                3 -> "#FF9800"; 4 -> "#FF5722"; 5 -> "#B71C1C"
                else -> "#9E9E9E"
            }
            views.setTextViewText(R.id.aqi_label, label)
            views.setTextViewText(R.id.aqi_city, city)
            views.setInt(R.id.aqi_dot, "setColorFilter", Color.parseColor(color))
            views.setOnClickPendingIntent(
                R.id.aqi_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("besafe://aqi"))
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
