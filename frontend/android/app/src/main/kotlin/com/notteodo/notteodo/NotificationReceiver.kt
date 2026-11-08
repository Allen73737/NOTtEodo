package com.notteodo.notteodo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.Shader
import android.os.Build
import androidx.core.app.NotificationCompat

class NotificationReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_REMINDERS = "notteodo_reminders"
        const val CHANNEL_DAILY = "notteodo_daily_engagement"
        const val CHANNEL_FOCUS = "notteodo_focus"
        const val ACTION_SHOW_NOTIFICATION = "com.notteodo.notteodo.SHOW_NOTIFICATION"
        const val ACTION_FOCUS_PAUSE = "com.notteodo.notteodo.FOCUS_PAUSE"
        const val ACTION_FOCUS_RESUME = "com.notteodo.notteodo.FOCUS_RESUME"
        const val ACTION_FOCUS_STOP = "com.notteodo.notteodo.FOCUS_STOP"

        fun createMascotLargeIcon(context: Context, isStreak: Boolean): Bitmap {
            val size = 128
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            // 1. Glowing Warm Terracotta/Gold circular badge
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val shader = RadialGradient(
                size / 2f, size / 2f, size / 2f,
                intArrayOf(
                    if (isStreak) 0xFFE8927C.toInt() else 0xFFE5B869.toInt(),
                    0xFFD9725B.toInt(),
                    0xFF7A2E1D.toInt()
                ),
                floatArrayOf(0.0f, 0.65f, 1.0f),
                Shader.TileMode.CLAMP
            )
            paint.shader = shader
            canvas.drawCircle(size / 2f, size / 2f, size / 2f - 4f, paint)

            // 2. Executive Gold Border Rim
            val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 4f
                color = 0xFFD4AF37.toInt()
            }
            canvas.drawCircle(size / 2f, size / 2f, size / 2f - 4f, rimPaint)

            // 3. Central Mascot Glyph (🔥 or 🦉 or ⚡)
            val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = 58f
                textAlign = Paint.Align.CENTER
            }
            val glyph = if (isStreak) "🔥" else "🦉"
            val yPos = (size / 2f - (textPaint.descent() + textPaint.ascent()) / 2f)
            canvas.drawText(glyph, size / 2f, yPos, textPaint)

            return bitmap
        }

        /**
         * Builds and posts a notification. Task and event reminders get a plain "open" tap;
         * daily nudges add the Check In and Focus shortcuts.
         */
        fun notify(context: Context, id: Int, title: String, message: String, channelId: String) {
            createNotificationChannels(context)
            val isDaily = channelId == CHANNEL_DAILY
            val isStreak = title.contains("Streak") || title.contains("🔥") || message.contains("streak")

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.ic_stat_notteodo)
                .setColor(0xFFD9725B.toInt())
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(if (isDaily) NotificationCompat.PRIORITY_DEFAULT else NotificationCompat.PRIORITY_HIGH)
                .setCategory(if (isDaily) NotificationCompat.CATEGORY_RECOMMENDATION else NotificationCompat.CATEGORY_REMINDER)
                .setAutoCancel(true)
                .setContentIntent(activityIntent(context, id, openIntent))

            if (isDaily) {
                builder.setLargeIcon(createMascotLargeIcon(context, isStreak))
                val checkIn = Intent(openIntent).putExtra("action", "check_in")
                val focus = Intent(openIntent).putExtra("action", "start_focus")
                builder
                    .addAction(R.drawable.ic_stat_notteodo, "Check in", activityIntent(context, id + 101, checkIn))
                    .addAction(R.drawable.ic_stat_notteodo, "Focus 25m", activityIntent(context, id + 102, focus))
            }

            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(id, builder.build())
        }

        private fun activityIntent(context: Context, requestCode: Int, intent: Intent): PendingIntent =
            PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                val remindersChannel = NotificationChannel(
                    CHANNEL_REMINDERS,
                    "NOTtEodo Reminders & Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Task due alerts, calendar reminders, and urgent notifications"
                    enableVibration(true)
                    setShowBadge(true)
                }

                val dailyChannel = NotificationChannel(
                    CHANNEL_DAILY,
                    "NOTtEodo Daily Inspiration & Habits",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Daily momentum, streak protection, and reflective check-ins"
                    enableVibration(true)
                    setShowBadge(true)
                }

                val focusChannel = NotificationChannel(
                    CHANNEL_FOCUS,
                    "NOTtEodo Focus Session",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Active focus session countdown and media controls"
                    enableVibration(false)
                    setShowBadge(false)
                }

                manager.createNotificationChannel(remindersChannel)
                manager.createNotificationChannel(dailyChannel)
                manager.createNotificationChannel(focusChannel)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == ACTION_FOCUS_PAUSE || action == ACTION_FOCUS_RESUME || action == ACTION_FOCUS_STOP) {
            val focusAction = when (action) {
                ACTION_FOCUS_PAUSE -> "pause"
                ACTION_FOCUS_RESUME -> "resume"
                else -> "stop"
            }
            MainActivity.instance?.onFocusActionReceived(focusAction)
            return
        }
        if (action != ACTION_SHOW_NOTIFICATION) return

        val id = intent.getIntExtra("id", System.currentTimeMillis().toInt())
        val title = intent.getStringExtra("title") ?: "NOTtEodo Reminder"
        val message = intent.getStringExtra("message") ?: ""
        val channelId = intent.getStringExtra("channelId") ?: CHANNEL_REMINDERS

        notify(context, id, title, message, channelId)
        ReminderScheduler.onFired(context, id)
    }
}
