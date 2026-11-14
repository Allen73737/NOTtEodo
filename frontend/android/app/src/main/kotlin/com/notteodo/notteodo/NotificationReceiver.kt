package com.notteodo.notteodo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class NotificationReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_REMINDERS = "notteodo_reminders"
        const val CHANNEL_DAILY = "notteodo_daily_engagement"
        const val CHANNEL_FOCUS = "notteodo_focus"
        const val ACTION_SHOW_NOTIFICATION = "com.notteodo.notteodo.SHOW_NOTIFICATION"
        const val ACTION_FOCUS_PAUSE = "com.notteodo.notteodo.FOCUS_PAUSE"
        const val ACTION_FOCUS_RESUME = "com.notteodo.notteodo.FOCUS_RESUME"
        const val ACTION_FOCUS_STOP = "com.notteodo.notteodo.FOCUS_STOP"
        const val ACTION_REMINDER_SNOOZE = "com.notteodo.notteodo.REMINDER_SNOOZE"

        fun getMascotGlyph(title: String, message: String): String {
            val t = title.lowercase()
            val m = message.lowercase()
            return when {
                t.contains("streak") || t.contains("flame") || t.contains("🔥") || m.contains("streak") -> "🔥"
                t.contains("morning") || t.contains("rise") || t.contains("sun") || t.contains("dawn") -> "🌅"
                t.contains("evening") || t.contains("night") || t.contains("sleep") || t.contains("recap") || t.contains("wind-down") -> "🌙"
                t.contains("focus") || t.contains("timer") || t.contains("sprint") || t.contains("⚡") -> "⚡"
                t.contains("task") || t.contains("goal") || t.contains("priority") || t.contains("win") || t.contains("halftime") -> "🎯"
                t.contains("dump") || t.contains("idea") || t.contains("clarity") || t.contains("note") -> "💡"
                t.contains("habit") || t.contains("ritual") || t.contains("conquer") -> "💪"
                t.contains("coffee") || t.contains("recharge") || t.contains("break") -> "☕"
                else -> "🦉"
            }
        }

        fun createAppLogoLargeIcon(context: Context, glyph: String): Bitmap {
            val size = 160
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            // 1. Dark luxury squircle backing (Tuscan obsidian)
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFF000000.toInt()
                style = Paint.Style.FILL
            }
            val rect = RectF(3f, 3f, size - 3f, size - 3f)
            canvas.drawRoundRect(rect, 34f, 34f, bgPaint)

            // Signature Terracotta border
            val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFD9725B.toInt()
                style = Paint.Style.STROKE
                strokeWidth = 3.5f
            }
            canvas.drawRoundRect(rect, 34f, 34f, borderPaint)

            // 2. Decode the official NOTtEodo App Logo
            var drawnAppLogo = false
            try {
                val opts = BitmapFactory.Options().apply {
                    inScaled = false
                    inSampleSize = 2
                }
                val logo = BitmapFactory.decodeResource(context.resources, R.drawable.notteodo_app_logo, opts)
                if (logo != null) {
                    val pad = 24f
                    val dest = RectF(pad, pad, size - pad, size - pad)
                    val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
                    canvas.drawBitmap(logo, null, dest, paint)
                    drawnAppLogo = true
                }
            } catch (_: Throwable) {}

            // Fallback to official ribbon monogram vector drawable if bitmap was not decoded
            if (!drawnAppLogo) {
                try {
                    val drawable = ContextCompat.getDrawable(context, R.drawable.ic_stat_notteodo)
                    if (drawable != null) {
                        val pad = 24
                        drawable.setBounds(pad, pad, size - pad, size - pad)
                        drawable.draw(canvas)
                        drawnAppLogo = true
                    }
                } catch (_: Throwable) {}
            }

            // 3. Contextual Badge (🔥, ⚡, 🌅, 🎯) on lower-right corner
            if (glyph.isNotEmpty() && glyph != "none") {
                val badgeSize = 44f
                val badgeCx = size - 26f
                val badgeCy = size - 26f
                val badgeBg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFFD9725B.toInt()
                    style = Paint.Style.FILL
                }
                canvas.drawCircle(badgeCx, badgeCy, badgeSize / 2f, badgeBg)

                val badgeBorder = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = 0xFF000000.toInt()
                    style = Paint.Style.STROKE
                    strokeWidth = 3f
                }
                canvas.drawCircle(badgeCx, badgeCy, badgeSize / 2f, badgeBorder)

                val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    textSize = 24f
                    textAlign = Paint.Align.CENTER
                }
                val textY = badgeCy - (textPaint.descent() + textPaint.ascent()) / 2f
                canvas.drawText(glyph, badgeCx, textY, textPaint)
            }

            return bitmap
        }

        /**
         * Builds and posts a lively, high-engagement on-device notification.
         */
        fun notify(context: Context, id: Int, title: String, message: String, channelId: String) {
            createNotificationChannels(context)
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            var targetChannel = channelId
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (manager.getNotificationChannel(targetChannel) == null) {
                    targetChannel = CHANNEL_REMINDERS
                }
            }
            val isDaily = targetChannel == CHANNEL_DAILY
            val glyph = getMascotGlyph(title, message)
            val textLogo = "NOTtEodo — Notes · Tasks · Life"

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val builder = NotificationCompat.Builder(context, targetChannel)
                .setSmallIcon(R.drawable.ic_stat_notteodo)
                .setColor(0xFFD9725B.toInt())
                .setContentTitle("$textLogo · $title")
                .setContentText(message)
                .setSubText(textLogo)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .setBigContentTitle("$textLogo · $title")
                        .bigText("$glyph $message")
                        .setSummaryText(textLogo)
                )
                .setLargeIcon(createAppLogoLargeIcon(context, glyph))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setCategory(if (isDaily) NotificationCompat.CATEGORY_EVENT else NotificationCompat.CATEGORY_REMINDER)
                .setVibrate(longArrayOf(0, 180, 90, 180, 90, 260))
                .setLights(0xFFD9725B.toInt(), 500, 500)
                .setAutoCancel(true)
                .setContentIntent(activityIntent(context, id, openIntent))

            if (isDaily) {
                val checkIn = Intent(openIntent).putExtra("action", "check_in")
                val focus = Intent(openIntent).putExtra("action", "start_focus")
                val quickNote = Intent(openIntent).putExtra("target_module", "notes")
                builder
                    .addAction(R.drawable.ic_stat_notteodo, "Check In ✨", activityIntent(context, id + 101, checkIn))
                    .addAction(R.drawable.ic_stat_notteodo, "Focus ⚡", activityIntent(context, id + 102, focus))
                    .addAction(R.drawable.ic_stat_notteodo, "Quick Note ✍️", activityIntent(context, id + 103, quickNote))
            } else {
                val openModule = Intent(openIntent).putExtra("action", "open_reminder")
                val snoozeIntent = Intent(context, NotificationReceiver::class.java).apply {
                    action = ACTION_REMINDER_SNOOZE
                    putExtra("id", id)
                    putExtra("title", title)
                    putExtra("message", message)
                    putExtra("channelId", targetChannel)
                }
                val snoozePending = PendingIntent.getBroadcast(
                    context,
                    id + 500,
                    snoozeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val focusIntent = Intent(context, NotificationReceiver::class.java).apply {
                    action = CadenceTimerManager.ACTION_TIMER_SET_FOCUS
                }
                val focusPending = PendingIntent.getBroadcast(
                    context,
                    id + 501,
                    focusIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                builder
                    .addAction(R.drawable.ic_stat_notteodo, "Snooze 15m ⏳", snoozePending)
                    .addAction(R.drawable.ic_stat_notteodo, "Focus 25m ⚡", focusPending)
                    .addAction(R.drawable.ic_stat_notteodo, "Open App 🚀", activityIntent(context, id + 104, openModule))
            }

            manager.notify(id, builder.build())
        }

        private fun activityIntent(context: Context, requestCode: Int, intent: Intent): PendingIntent =
            PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        fun createNotificationChannels(context: Context) {
            CadenceTimerManager.createChannel(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                val remindersChannel = NotificationChannel(
                    CHANNEL_REMINDERS,
                    "NOTtEodo Reminders & Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Task due alerts, calendar reminders, and urgent notifications"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 160, 90, 220)
                    enableLights(true)
                    lightColor = 0xFFD9725B.toInt()
                    setShowBadge(true)
                }

                val dailyChannel = NotificationChannel(
                    CHANNEL_DAILY,
                    "NOTtEodo Daily Inspiration & Habits",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Daily momentum, streak protection, and reflective check-ins"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 140, 80, 180)
                    enableLights(true)
                    lightColor = 0xFFD9725B.toInt()
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

        // 1. Focus session actions from media style notifications
        if (action == ACTION_FOCUS_PAUSE || action == ACTION_FOCUS_RESUME || action == ACTION_FOCUS_STOP) {
            val focusAction = when (action) {
                ACTION_FOCUS_PAUSE -> "pause"
                ACTION_FOCUS_RESUME -> "resume"
                else -> "stop"
            }
            MainActivity.instance?.onFocusActionReceived(focusAction)
            return
        }

        // 2. Interactive Live On-Device Cadence Timer Actions
        when (action) {
            CadenceTimerManager.ACTION_TIMER_EXTEND -> {
                CadenceTimerManager.extendTimer(context, 900)
                return
            }
            CadenceTimerManager.ACTION_TIMER_RESET -> {
                CadenceTimerManager.resetTimer(context)
                return
            }
            CadenceTimerManager.ACTION_TIMER_SET_FOCUS -> {
                CadenceTimerManager.startTimer(context, 1500, "25m Pomodoro Focus")
                return
            }
            CadenceTimerManager.ACTION_TIMER_CANCEL -> {
                CadenceTimerManager.cancelTimer(context)
                return
            }
            CadenceTimerManager.ACTION_TIMER_EXPIRED -> {
                CadenceTimerManager.onTimerExpired(context)
                return
            }
            CadenceTimerManager.ACTION_TIMER_START_PRESET -> {
                val duration = intent.getIntExtra("duration_seconds", 10800)
                val timerTitle = intent.getStringExtra("title") ?: "3-Hour Cadence Timer"
                CadenceTimerManager.startTimer(context, duration, timerTitle)
                return
            }
            ACTION_REMINDER_SNOOZE -> {
                val id = intent.getIntExtra("id", 0)
                val title = intent.getStringExtra("title") ?: "NOTtEodo Reminder"
                val message = intent.getStringExtra("message") ?: ""
                val channelId = intent.getStringExtra("channelId") ?: CHANNEL_REMINDERS

                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.cancel(id)

                // Re-arm reminder 15 minutes in the future
                val snoozeTime = System.currentTimeMillis() + (15 * 60 * 1000L)
                ReminderScheduler.schedule(context, id + 9000, "Snoozed: $title", message, snoozeTime, channelId, false)
                return
            }
        }

        // 3. Normal Scheduled Alarms & In-App Reminders
        if (action != ACTION_SHOW_NOTIFICATION) return

        val id = intent.getIntExtra("id", System.currentTimeMillis().toInt())
        val title = intent.getStringExtra("title") ?: "NOTtEodo Reminder"
        val message = intent.getStringExtra("message") ?: ""
        val channelId = intent.getStringExtra("channelId") ?: CHANNEL_REMINDERS
        val soundId = intent.getStringExtra("soundId")

        notify(context, id, title, message, channelId)
        ReminderScheduler.onFired(context, id)

        // Play the user's chosen aesthetic sound
        val isAlarm = (channelId == CHANNEL_REMINDERS)
        val chosenSound = soundId ?: if (isAlarm) {
            AestheticAudioSynthesizer.getSavedAlarmSound(context).first
        } else {
            AestheticAudioSynthesizer.getSavedNotificationSound(context).first
        }
        AestheticAudioSynthesizer.playAestheticTone(context, chosenSound, isAlarm = isAlarm)
    }
}
