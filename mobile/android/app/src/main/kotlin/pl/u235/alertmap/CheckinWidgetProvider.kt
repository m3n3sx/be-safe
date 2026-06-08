package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class CheckinWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_checkin)
            val sub = widgetData.getString("checkin_sub", "Tapnij aby się zameldować")
            views.setTextViewText(R.id.checkin_sub, sub)
            views.setOnClickPendingIntent(
                R.id.checkin_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("besafe://checkin"))
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
