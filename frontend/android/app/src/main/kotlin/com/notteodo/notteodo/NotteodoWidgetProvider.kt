package com.notteodo.notteodo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
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

    private companion object {
        // Everything sent to the launcher travels in one Binder parcel, capped near 1 MB.
        // A Widget Studio image larger than this makes the launcher show "Can't load widget",
        // so it is scaled down to stay well under the cap (ARGB_8888: 4 bytes per pixel).
        const val MAX_BITMAP_BYTES = 700 * 1024
    }

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
        val editorial = (widgetData.getString("widget_style", "bento") ?: "bento") == "editorial"
        val layout = if (editorial) R.layout.notteodo_widget_editorial else R.layout.notteodo_widget_layout

        val streakCount = readInt(widgetData, "streak_count", 1)
        val pendingTasks = readInt(widgetData, "pending_tasks", 0)
        val nextTasks = (widgetData.getString("next_tasks", "") ?: "")
            .split("\n").filter { it.isNotBlank() }.take(3)
        val quote = widgetData.getString("daily_quote", "Make today deliberate.") ?: "Make today deliberate."
        // "Level 6 · 2 more to Ten Pages", kept current by the app.
        val progress = widgetData.getString("progress_text", null)?.takeIf { it.isNotBlank() }
        val date = SimpleDateFormat("EEEE d MMMM", Locale.getDefault()).format(Date()).uppercase(Locale.getDefault())
        val bitmap = loadStudioImage(widgetData.getString("notteodo_widget_image", null))

        appWidgetIds.forEach { widgetId ->
            fun build(withImage: Boolean) = RemoteViews(context.packageName, layout).apply {
                if (withImage && bitmap != null) {
                    // A design from the Widget Studio, redrawn by the app with fresh data.
                    setImageViewBitmap(R.id.widget_image, bitmap)
                    setViewVisibility(R.id.widget_image, View.VISIBLE)
                    setViewVisibility(R.id.widget_native_container, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_image, View.GONE)
                    setViewVisibility(R.id.widget_native_container, View.VISIBLE)
                    setTextViewText(R.id.widget_date, date)
                    setTextViewText(R.id.widget_streak, if (streakCount == 1) "1 day" else "$streakCount days")
                    if (editorial) {
                        setTextViewText(
                            R.id.widget_tasks,
                            when (pendingTasks) {
                                0 -> "A clear day."
                                1 -> "1 thing to do"
                                else -> "$pendingTasks things to do"
                            }
                        )
                        setTextViewText(R.id.widget_next, nextTasks.joinToString("\n") { "○  $it" })
                        val run = if (streakCount == 1) "1 day in a row" else "$streakCount days in a row"
                        setTextViewText(R.id.widget_streak, if (progress != null) "$run  ·  $progress" else run)
                    } else {
                        setTextViewText(R.id.widget_count, pendingTasks.toString())
                        setTextViewText(R.id.widget_tasks, if (pendingTasks == 1) "open task" else "open tasks")
                        setTextViewText(
                            R.id.widget_quote,
                            if (nextTasks.isNotEmpty()) nextTasks.joinToString("\n") { "○  $it" } else quote
                        )
                        setTextViewText(R.id.widget_footer, progress ?: "Open NOTtEodo  →")
                    }
                }
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_native_container, pendingIntent)
            }

            try {
                appWidgetManager.updateAppWidget(widgetId, build(withImage = true))
            } catch (e: Exception) {
                // If the image still can't be delivered, show the live card instead of an error.
                appWidgetManager.updateAppWidget(widgetId, build(withImage = false))
            }
        }
    }

    /** Older builds stored some counts as Long; read either without throwing. */
    private fun readInt(prefs: SharedPreferences, key: String, fallback: Int): Int =
        when (val v = prefs.all[key]) {
            is Int -> v
            is Long -> v.toInt()
            is String -> v.toIntOrNull() ?: fallback
            else -> fallback
        }

    /** Decodes the Studio image, scaled so it fits the launcher's parcel limit. */
    private fun loadStudioImage(path: String?): Bitmap? {
        if (path == null) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            while ((bounds.outWidth / sample).toLong() * (bounds.outHeight / sample) * 4 > MAX_BITMAP_BYTES * 4L) sample *= 2
            val decoded = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample }) ?: return null

            val bytes = decoded.width.toLong() * decoded.height * 4
            if (bytes <= MAX_BITMAP_BYTES) return decoded
            val scale = Math.sqrt(MAX_BITMAP_BYTES.toDouble() / bytes)
            val scaled = Bitmap.createScaledBitmap(
                decoded,
                (decoded.width * scale).toInt().coerceAtLeast(1),
                (decoded.height * scale).toInt().coerceAtLeast(1),
                true
            )
            if (scaled != decoded) decoded.recycle()
            scaled
        } catch (e: Throwable) {
            null
        }
    }
}
