package com.notteodo.notteodo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class NotteodoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            7771,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.notteodo_widget_layout).apply {
                val imagePath = widgetData.getString("notteodo_widget_image", null)
                val hasValidImage = imagePath != null && File(imagePath).exists()

                if (hasValidImage) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_image, bitmap)
                        setViewVisibility(R.id.widget_image, View.VISIBLE)
                        setViewVisibility(R.id.widget_native_container, View.GONE)
                    } else {
                        setViewVisibility(R.id.widget_image, View.GONE)
                        setViewVisibility(R.id.widget_native_container, View.VISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_image, View.GONE)
                    setViewVisibility(R.id.widget_native_container, View.VISIBLE)

                    val streakCount = widgetData.getInt("streak_count", 1)
                    val streakText = widgetData.getString("streak_text", null) ?: "🔥 ${streakCount}d Streak"
                    val pendingTasks = widgetData.getInt("pending_tasks", 0)
                    val tasksText = widgetData.getString("tasks_text", null) ?: "$pendingTasks Tasks Pending"
                    val quote = widgetData.getString("daily_quote", "Make today deliberate.")

                    setTextViewText(R.id.widget_streak, streakText)
                    setTextViewText(R.id.widget_tasks, "✓ $tasksText")
                    setTextViewText(R.id.widget_quote, quote)
                }

                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_native_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
