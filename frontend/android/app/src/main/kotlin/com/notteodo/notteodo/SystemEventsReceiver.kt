package com.notteodo.notteodo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * The only exported receiver: it listens for system broadcasts (boot, clock and timezone
 * changes) and re-arms saved reminders. Notification delivery itself stays in the
 * non-exported [NotificationReceiver], so other apps cannot post notifications as NOTtEodo.
 */
class SystemEventsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED -> ReminderScheduler.restoreAll(context)
        }
    }
}
