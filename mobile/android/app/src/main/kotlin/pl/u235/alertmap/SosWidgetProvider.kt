package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget SOS — duży czerwony przycisk na ekranie głównym.
 * Tap otwiera aplikację bezpośrednio na ekranie SOS (besafe://sos).
 * NIE wyzwala alarmu automatycznie (ochrona przed przypadkowym tapnięciem).
 */
class SosWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_sos)
            val pending = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("besafe://sos")
            )
            views.setOnClickPendingIntent(R.id.sos_root, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
