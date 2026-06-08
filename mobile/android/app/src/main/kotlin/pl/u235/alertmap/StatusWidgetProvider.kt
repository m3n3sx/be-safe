package pl.u235.alertmap

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget "Stan zagrożeń" — poziom bezpieczeństwa N/10, komunikat i liczba
 * alertów w okolicy. Dane wstrzykiwane z Fluttera przez home_widget
 * (WidgetService.pushSafety). Tap otwiera mapę (besafe://status).
 */
class StatusWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_status)

            val level = widgetData.getInt("safety_level", 10)
            val message = widgetData.getString("safety_message", "Wszystko w porządku")
            val alerts = widgetData.getString("safety_alerts", "Twoja okolica jest bezpieczna")

            // Kolor wg progów (zgodnie z _orbColor w home_screen.dart)
            val color = when {
                level >= 7 -> Color.parseColor("#6BE332") // zielony
                level >= 4 -> Color.parseColor("#EB6A00") // pomarańczowy
                else -> Color.parseColor("#CE2200")       // czerwony
            }

            views.setTextViewText(R.id.status_score, level.toString())
            views.setTextColor(R.id.status_score, color)
            views.setInt(R.id.status_dot, "setColorFilter", color)
            views.setTextViewText(R.id.status_msg, message)
            views.setTextViewText(R.id.status_alerts, alerts)

            val pending = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("besafe://status")
            )
            views.setOnClickPendingIntent(R.id.status_root, pending)

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
