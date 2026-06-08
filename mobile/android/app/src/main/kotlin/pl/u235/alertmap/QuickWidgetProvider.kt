package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick)
            fun pi(uri: String) = HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse(uri)
            )
            views.setOnClickPendingIntent(R.id.quick_sos, pi("besafe://sos"))
            views.setOnClickPendingIntent(R.id.quick_fakecall, pi("besafe://fakecall"))
            views.setOnClickPendingIntent(R.id.quick_report, pi("besafe://report"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
