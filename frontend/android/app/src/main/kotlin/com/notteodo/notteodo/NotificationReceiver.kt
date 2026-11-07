package com.notteodo.notteodo

import android.app.AlarmManager
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

        fun scheduleNext3HourCadence(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val nextTriggerMillis = System.currentTimeMillis() + (3 * 60 * 60 * 1000L) // +3 hours
            
            val prompts = arrayOf(
                Pair("🔥 Streak Alert: Don't Break the Chain!", "Your daily momentum is calling. 1 tap saves your unbroken flame!"),
                Pair("🦉 Nodo Reality Check: 60 Seconds", "Hey! Staring at your to-do list won't check it off. Knock out one tiny task now."),
                Pair("⚡ Midday Focus Recharge", "Drop the frantic urgency. Pause for 2 minutes and realign your top priority."),
                Pair("🛡️ Streak Shield: Flame Protected", "Your daily habits compound into mastery. Check in now to lock in today's victory!"),
                Pair("🌙 Evening Zen Reflection", "Close your loops before sleep. Review what you conquered today in 60 seconds.")
            )
            val selected = prompts.random()

            val intent = Intent(context, NotificationReceiver::class.java).apply {
                action = ACTION_SHOW_NOTIFICATION
                putExtra("id", 9999)
                putExtra("title", selected.first)
                putExtra("message", selected.second)
                putExtra("channelId", CHANNEL_DAILY)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                9999,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val info = AlarmManager.AlarmClockInfo(nextTriggerMillis, pendingIntent)
                    alarmManager.setAlarmClock(info, pendingIntent)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTriggerMillis, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, nextTriggerMillis, pendingIntent)
                }
            } catch (_: Exception) {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextTriggerMillis, pendingIntent)
                    } else {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, nextTriggerMillis, pendingIntent)
                    }
                } catch (_: Exception) {}
            }
        }

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
                    NotificationManager.IMPORTANCE_HIGH
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

        val id = intent.getIntExtra("id", System.currentTimeMillis().toInt())
        val title = intent.getStringExtra("title") ?: "NOTtEodo Reminder"
        val message = intent.getStringExtra("message") ?: ""
        val channelId = intent.getStringExtra("channelId") ?: CHANNEL_REMINDERS

        createNotificationChannels(context)

        val isStreak = title.contains("Streak") || title.contains("🔥") || message.contains("streak")
        val largeIcon = createMascotLargeIcon(context, isStreak)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action 1: Instant 1-tap Check In
        val checkInIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "check_in")
        }
        val checkInPending = PendingIntent.getActivity(
            context,
            id + 101,
            checkInIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action 2: 25m Pomodoro Focus
        val focusIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "start_focus")
        }
        val focusPending = PendingIntent.getActivity(
            context,
            id + 102,
            focusIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setLargeIcon(largeIcon)
            .setColor(0xFFD9725B.toInt())
            .setContentTitle(title)
            .setContentText(message)
            .setSubText(if (isStreak) "🔥 STREAK MOMENTUM" else "🦉 NODO COMPANION")
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(R.mipmap.ic_launcher, "🔥 Check In", checkInPending)
            .addAction(R.mipmap.ic_launcher, "⚡ Focus 25m", focusPending)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, builder.build())

        // Automatically reschedule next 3-hour device notification in Android OS
        if (channelId == CHANNEL_DAILY) {
            scheduleNext3HourCadence(context)
        }
    }
}
