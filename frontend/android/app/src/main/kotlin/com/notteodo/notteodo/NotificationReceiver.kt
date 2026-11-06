package com.notteodo.notteodo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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

        val id = intent.getIntExtra("id", System.currentTimeMillis().toInt())
        val title = intent.getStringExtra("title") ?: "NOTtEodo Reminder"
        val message = intent.getStringExtra("message") ?: ""
        val channelId = intent.getStringExtra("channelId") ?: CHANNEL_REMINDERS

        createNotificationChannels(context)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, builder.build())
    }
}

