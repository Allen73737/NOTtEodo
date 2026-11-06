package com.notteodo.notteodo

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class FocusSanctuaryTileService : TileService() {
    companion object {
        var isFocusActive: Boolean = false
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    private fun updateTileState() {
        qsTile?.let {
            it.state = if (isFocusActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            it.label = if (isFocusActive) "Focus Active" else "Focus Sanctuary"
            it.updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        isFocusActive = !isFocusActive
        updateTileState()

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", if (isFocusActive) "start_focus" else "stop_focus")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = android.app.PendingIntent.getActivity(
                this,
                9912,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}

