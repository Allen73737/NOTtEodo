package com.notteodo.notteodo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NotteodoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val targetModule = widgetData.getString("widget_target_module", "home") ?: "home"
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", targetModule)
            putExtra("target_module", targetModule)
            data = Uri.parse("notteodo://module/$targetModule")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            7771,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // The live layout follows the app's view: type on paper, or the dark card.
        val editorial = (widgetData.getString("widget_style", "editorial") ?: "editorial") == "editorial"
        val layout = if (editorial) R.layout.notteodo_widget_editorial else R.layout.notteodo_widget_layout

        val streakCount = widgetData.getInt("streak_count", 1)
        val pendingTasks = widgetData.getInt("pending_tasks", 0)
        val nextTasks = (widgetData.getString("next_tasks", "") ?: "")
            .split("\n").filter { it.isNotBlank() }.take(3)
        val quote = widgetData.getString("daily_quote", "Make today deliberate.") ?: "Make today deliberate."

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layout).apply {
                val imagePath = widgetData.getString("notteodo_widget_image", null)
                val bitmap = if (imagePath != null && File(imagePath).exists()) BitmapFactory.decodeFile(imagePath) else null

                if (bitmap != null) {
                    // A design from the Widget Studio, redrawn by the app with fresh data.
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    setViewVisibility(R.id.widget_image, View.VISIBLE)
                    setViewVisibility(R.id.widget_native_container, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_image, View.GONE)
                    setViewVisibility(R.id.widget_native_container, View.VISIBLE)
                    if (editorial) {
                        setTextViewText(
                            R.id.widget_date,
                            SimpleDateFormat("EEEE d MMMM", Locale.getDefault()).format(Date()).uppercase(Locale.getDefault())
                        )
                        setTextViewText(
                            R.id.widget_tasks,
                            when (pendingTasks) {
                                0 -> "A clear day."
                                1 -> "1 thing to do"
                                else -> "$pendingTasks things to do"
                            }
                        )
                        setTextViewText(R.id.widget_next, nextTasks.joinToString("\n") { "○  $it" })
                        setTextViewText(R.id.widget_streak, if (streakCount == 1) "1 day in a row" else "$streakCount days in a row")
                    } else {
                        setTextViewText(R.id.widget_streak, "🔥 ${streakCount}d")
                        setTextViewText(R.id.widget_tasks, "✓ $pendingTasks open")
                        setTextViewText(
                            R.id.widget_quote,
                            if (nextTasks.isNotEmpty()) nextTasks.joinToString("\n") { "· $it" } else quote
                        )
                    }
                }

                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_native_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
