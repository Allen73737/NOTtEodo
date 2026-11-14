package com.notteodo.notteodo

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Manages the live on-device notification panel countdown timer.
 *
 * Implements Android's native Chronometer countdown ([NotificationCompat.Builder.setUsesChronometer],
 * [NotificationCompat.Builder.setChronometerCountDown]), rendering a live, second-by-second ticking
 * timer directly in the device's notification shade and lockscreen.
 *
 * When the countdown reaches 0:00:00:
 * 1. AlarmManager exact alarm triggers [onTimerExpired]
 * 2. Plays the user's selected reminder sound synthesized via [AestheticAudioSynthesizer]
 * 3. Displays a rich Tuscan luxury completion notification with quick 1-tap restart actions
 */
object CadenceTimerManager {
    const val CHANNEL_CADENCE_TIMER = "notteodo_cadence_timer"
    const val NOTIFICATION_ID_CADENCE_TIMER = 7701
    const val NOTIFICATION_ID_CADENCE_COMPLETION = 7702

    const val ACTION_TIMER_EXTEND = "com.notteodo.notteodo.TIMER_EXTEND"
    const val ACTION_TIMER_RESET = "com.notteodo.notteodo.TIMER_RESET"
    const val ACTION_TIMER_SET_FOCUS = "com.notteodo.notteodo.TIMER_SET_FOCUS"
    const val ACTION_TIMER_CANCEL = "com.notteodo.notteodo.TIMER_CANCEL"
    const val ACTION_TIMER_EXPIRED = "com.notteodo.notteodo.TIMER_EXPIRED"
    const val ACTION_TIMER_START_PRESET = "com.notteodo.notteodo.TIMER_START_PRESET"

    private const val PREFS_TIMER = "notteodo_live_timer"

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_CADENCE_TIMER) == null) {
                val channel = NotificationChannel(
                    CHANNEL_CADENCE_TIMER,
                    "NOTtEodo Live Cadence & Timers",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Active on-device countdown timer in notification shade"
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    fun startTimer(
        context: Context,
        durationSeconds: Int,
        title: String? = null,
        soundId: String? = null
    ) {
        val now = System.currentTimeMillis()
        val targetTimeMillis = now + (durationSeconds * 1000L)
        val displayTitle = title ?: when (durationSeconds) {
            900 -> "15m Focus Sprint"
            1500 -> "25m Pomodoro Focus"
            2700 -> "45m Deep Work"
            3600 -> "1-Hour Horizon"
            7200 -> "2-Hour Deep Cadence"
            10800 -> "3-Hour Cadence Timer"
            else -> "${durationSeconds / 60}m Cadence Timer"
        }

        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("is_active", true)
            .putLong("start_time", now)
            .putLong("target_time", targetTimeMillis)
            .putInt("total_seconds", durationSeconds)
            .putString("title", displayTitle)
            .putString("sound_id", soundId ?: "")
            .apply()

        armAlarm(context, targetTimeMillis)
        updateNotification(context, targetTimeMillis, durationSeconds, displayTitle)
    }

    fun extendTimer(context: Context, additionalSeconds: Int = 900) {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("is_active", false)) {
            startTimer(context, additionalSeconds, "+15m Focus Extension")
            return
        }

        val currentTarget = prefs.getLong("target_time", System.currentTimeMillis())
        val newTarget = currentTarget + (additionalSeconds * 1000L)
        val totalSecs = prefs.getInt("total_seconds", 10800) + additionalSeconds
        val title = prefs.getString("title", "Cadence Timer") ?: "Cadence Timer"

        prefs.edit()
            .putLong("target_time", newTarget)
            .putInt("total_seconds", totalSecs)
            .apply()

        armAlarm(context, newTarget)
        updateNotification(context, newTarget, totalSecs, title)
    }

    fun resetTimer(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        val totalSecs = prefs.getInt("total_seconds", 10800)
        val title = prefs.getString("title", "3-Hour Cadence Timer") ?: "3-Hour Cadence Timer"
        val soundId = prefs.getString("sound_id", null)
        startTimer(context, totalSecs, title, soundId)
    }

    fun cancelTimer(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("is_active", false).apply()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        alarmManager?.cancel(getExpiredPendingIntent(context))

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID_CADENCE_TIMER)
    }

    fun onTimerExpired(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        val title = prefs.getString("title", "Cadence Timer") ?: "Cadence Timer"
        var soundId = prefs.getString("sound_id", null)
        if (soundId.isNullOrEmpty()) {
            soundId = AestheticAudioSynthesizer.getSavedAlarmSound(context).first
        }

        prefs.edit().putBoolean("is_active", false).apply()

        // Cancel live ongoing ticking notification
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID_CADENCE_TIMER)

        // Play the user's selected reminder sound
        AestheticAudioSynthesizer.playAestheticTone(context, soundId, isAlarm = true)

        // Display completion alert
        showCompletionNotification(context, title)
    }

    fun getStatus(context: Context): Map<String, Any> {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_active", false)
        if (!isActive) {
            return mapOf("isActive" to false, "remainingSeconds" to 0, "totalSeconds" to 0, "title" to "")
        }

        val target = prefs.getLong("target_time", 0L)
        val now = System.currentTimeMillis()
        val remaining = ((target - now) / 1000L).coerceAtLeast(0L)
        val total = prefs.getInt("total_seconds", 0)
        val title = prefs.getString("title", "") ?: ""

        if (remaining <= 0) {
            return mapOf("isActive" to false, "remainingSeconds" to 0, "totalSeconds" to total, "title" to title)
        }
        return mapOf(
            "isActive" to true,
            "remainingSeconds" to remaining,
            "totalSeconds" to total,
            "title" to title
        )
    }

    fun restore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_TIMER, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("is_active", false)) return

        val targetTime = prefs.getLong("target_time", 0L)
        val now = System.currentTimeMillis()
        if (targetTime <= now) {
            onTimerExpired(context)
        } else {
            val totalSeconds = prefs.getInt("total_seconds", 10800)
            val title = prefs.getString("title", "Cadence Timer") ?: "Cadence Timer"
            armAlarm(context, targetTime)
            updateNotification(context, targetTime, totalSeconds, title)
        }
    }

    private fun armAlarm(context: Context, triggerAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pending = getExpiredPendingIntent(context)
        try {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        }
    }

    private fun getExpiredPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_EXPIRED
        }
        return PendingIntent.getBroadcast(
            context,
            7700,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun updateNotification(
        context: Context,
        targetTimeMillis: Long,
        totalSeconds: Int,
        title: String
    ) {
        createChannel(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val now = System.currentTimeMillis()
        val remainingMillis = (targetTimeMillis - now).coerceAtLeast(0)
        val remainingSeconds = (remainingMillis / 1000).toInt()

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "open_cadence_timer")
        }
        val contentPending = PendingIntent.getActivity(
            context,
            7710,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: +15m Extend
        val extendIntent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_EXTEND
        }
        val extendPending = PendingIntent.getBroadcast(
            context,
            7711,
            extendIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: 🔄 Reset
        val resetIntent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_RESET
        }
        val resetPending = PendingIntent.getBroadcast(
            context,
            7712,
            resetIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: ⚡ Focus 25m
        val focusIntent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_SET_FOCUS
        }
        val focusPending = PendingIntent.getBroadcast(
            context,
            7713,
            focusIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: ✕ Dismiss
        val cancelIntent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_CANCEL
        }
        val cancelPending = PendingIntent.getBroadcast(
            context,
            7714,
            cancelIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val largeIcon = NotificationReceiver.createAppLogoLargeIcon(context, "⏳")

        val builder = NotificationCompat.Builder(context, CHANNEL_CADENCE_TIMER)
            .setSmallIcon(R.drawable.ic_stat_notteodo)
            .setColor(0xFFD9725B.toInt())
            .setLargeIcon(largeIcon)
            .setContentTitle("NOTtEodo · $title")
            .setContentText("Live countdown in progress · Ticking down to intentional pause")
            .setSubText("Live Cadence Timer")
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(targetTimeMillis)
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setProgress(totalSeconds, (totalSeconds - remainingSeconds).coerceIn(0, totalSeconds), false)
            .setContentIntent(contentPending)
            .addAction(R.drawable.ic_stat_notteodo, "+15m Extend", extendPending)
            .addAction(R.drawable.ic_stat_notteodo, "🔄 Reset", resetPending)
            .addAction(R.drawable.ic_stat_notteodo, "⚡ Focus 25m", focusPending)
            .addAction(R.drawable.ic_stat_notteodo, "✕ Dismiss", cancelPending)

        manager.notify(NOTIFICATION_ID_CADENCE_TIMER, builder.build())
    }

    private fun showCompletionNotification(context: Context, title: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        NotificationReceiver.createNotificationChannels(context)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "cadence_completed")
        }
        val contentPending = PendingIntent.getActivity(
            context,
            7720,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Restart 3h
        val restart3hIntent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_START_PRESET
            putExtra("duration_seconds", 10800)
            putExtra("title", "3-Hour Cadence Timer")
        }
        val restart3hPending = PendingIntent.getBroadcast(
            context,
            7721,
            restart3hIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Focus 25m
        val focus25Intent = Intent(context, NotificationReceiver::class.java).apply {
            action = ACTION_TIMER_SET_FOCUS
        }
        val focus25Pending = PendingIntent.getBroadcast(
            context,
            7722,
            focus25Intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val largeIcon = NotificationReceiver.createAppLogoLargeIcon(context, "🏆")

        val builder = NotificationCompat.Builder(context, NotificationReceiver.CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_stat_notteodo)
            .setColor(0xFFD9725B.toInt())
            .setLargeIcon(largeIcon)
            .setContentTitle("NOTtEodo · $title Complete ✨")
            .setContentText("Your intentional cadence reached zero. Take a deep breath or begin your next horizon.")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("NOTtEodo · $title Complete ✨")
                    .bigText("⏳ Cadence Reached Zero!\n\nYour intentional rhythm has concluded. Step back from the screen, hydrate, celebrate your progress, or launch your next focus ritual.")
                    .setSummaryText("NOTtEodo · Cadence Reached 0")
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(0, 200, 100, 200, 100, 350))
            .setLights(0xFFD9725B.toInt(), 500, 500)
            .setAutoCancel(true)
            .setContentIntent(contentPending)
            .addAction(R.drawable.ic_stat_notteodo, "Start 3h ⏳", restart3hPending)
            .addAction(R.drawable.ic_stat_notteodo, "Focus 25m ⚡", focus25Pending)
            .addAction(R.drawable.ic_stat_notteodo, "Open App 🚀", contentPending)

        manager.notify(NOTIFICATION_ID_CADENCE_COMPLETION, builder.build())
    }
}

