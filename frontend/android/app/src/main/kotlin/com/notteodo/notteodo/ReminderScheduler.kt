package com.notteodo.notteodo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

/**
 * The single owner of every scheduled notification.
 *
 * Each alarm is also written to SharedPreferences, so it survives a reboot or a clock
 * change ([restoreAll]) and can be cancelled later from Dart by id. Engagement nudges
 * marked `repeatDaily` re-arm themselves 24 hours later when they fire, so the user's
 * chosen times (already filtered by quiet hours in Dart) keep going without the app open.
 */
object ReminderScheduler {
    private const val PREFS = "notteodo_alarms"

    fun schedule(
        context: Context,
        id: Int,
        title: String,
        message: String,
        triggerAtMillis: Long,
        channelId: String,
        repeatDaily: Boolean,
        soundId: String? = null,
    ) {
        val entry = JSONObject()
            .put("title", title)
            .put("message", message)
            .put("trigger", triggerAtMillis)
            .put("channel", channelId)
            .put("repeat", repeatDaily)
            .put("sound", soundId ?: "")
        prefs(context).edit().putString(id.toString(), entry.toString()).apply()
        arm(context, id, title, message, triggerAtMillis, channelId, soundId)
    }

    fun cancel(context: Context, id: Int) {
        prefs(context).edit().remove(id.toString()).apply()
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(pendingIntent(context, id, null, null))
    }

    fun cancelAll(context: Context) {
        val ids = prefs(context).all.keys.mapNotNull { it.toIntOrNull() }
        ids.forEach { cancel(context, it) }
    }

    /** Called by the receiver when alarm [id] fires: forget it, or move a daily one forward. */
    fun onFired(context: Context, id: Int) {
        val raw = prefs(context).getString(id.toString(), null) ?: return
        val entry = runCatching { JSONObject(raw) }.getOrNull()
        if (entry == null || !entry.optBoolean("repeat")) {
            prefs(context).edit().remove(id.toString()).apply()
            return
        }
        var next = entry.getLong("trigger")
        val now = System.currentTimeMillis()
        while (next <= now) next += DAY_MILLIS
        val sound = entry.optString("sound").takeIf { it.isNotEmpty() }
        schedule(context, id, entry.getString("title"), entry.getString("message"), next, entry.getString("channel"), true, sound)
    }

    /** Re-arms everything after a reboot or time change; missed one-off reminders are shown once now. */
    fun restoreAll(context: Context) {
        CadenceTimerManager.restore(context)
        val now = System.currentTimeMillis()
        for ((key, value) in prefs(context).all) {
            val id = key.toIntOrNull() ?: continue
            val entry = runCatching { JSONObject(value as String) }.getOrNull() ?: continue
            var trigger = entry.getLong("trigger")
            if (trigger <= now) {
                if (!entry.optBoolean("repeat")) {
                    // Missed while the phone was off: deliver it late rather than silently.
                    trigger = now + 5_000
                } else {
                    while (trigger <= now) trigger += DAY_MILLIS
                }
            }
            val sound = entry.optString("sound").takeIf { it.isNotEmpty() }
            schedule(context, id, entry.getString("title"), entry.getString("message"), trigger, entry.getString("channel"), entry.optBoolean("repeat"), sound)
        }
    }

    private fun arm(
        context: Context,
        id: Int,
        title: String,
        message: String,
        triggerAtMillis: Long,
        channelId: String,
        soundId: String? = null
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val pending = pendingIntent(context, id, Triple(title, message, channelId), soundId)
        try {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
        }
    }

    private fun pendingIntent(
        context: Context,
        id: Int,
        content: Triple<String, String, String>?,
        soundId: String? = null
    ): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_SHOW_NOTIFICATION
            putExtra("id", id)
            if (content != null) {
                putExtra("title", content.first)
                putExtra("message", content.second)
                putExtra("channelId", content.third)
                if (!soundId.isNullOrEmpty()) {
                    putExtra("soundId", soundId)
                }
            }
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private const val DAY_MILLIS = 24 * 60 * 60 * 1000L
}
