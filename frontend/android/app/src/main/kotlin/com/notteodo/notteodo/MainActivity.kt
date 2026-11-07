package com.notteodo.notteodo

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CalendarContract
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterFragmentActivity() {
    companion object {
        var instance: MainActivity? = null
        const val FOCUS_NOTIFICATION_ID = 88888
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var focusActionChannel: MethodChannel? = null
    private val RECORD_AUDIO_REQ = 2001
    private val SPEECH_ACTIVITY_REQ = 2002
    private val POST_NOTIF_REQ = 2003

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
        NotificationReceiver.createNotificationChannels(this)
        handleTileIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleTileIntent(intent)
    }

    private fun handleTileIntent(intent: Intent?) {
        val action = intent?.getStringExtra("action") ?: return
        thread {
            Thread.sleep(700)
            runOnUiThread {
                focusActionChannel?.invokeMethod("onQuickTileAction", mapOf("action" to action))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Focus Actions Channel for notifications
        focusActionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/focus_actions")

        // 1. Privacy Window Manager Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/privacy")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        if (call.arguments == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Native Speech Recognition Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        val hasService = SpeechRecognizer.isRecognitionAvailable(this)
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                        val canHandleIntent = intent.resolveActivity(packageManager) != null
                        result.success(hasService || canHandleIntent)
                    }
                    "listen" -> {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                            != PackageManager.PERMISSION_GRANTED) {
                            pendingSpeechResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.RECORD_AUDIO),
                                RECORD_AUDIO_REQ
                            )
                        } else {
                            startSpeechListening(result)
                        }
                    }
                    "stop" -> {
                        try {
                            speechRecognizer?.stopListening()
                        } catch (_: Exception) {}
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. Native Acoustic Audio Synthesizer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playSound" -> {
                        val soundId = call.argument<String>("soundId") ?: "velvet_obsidian"
                        val isAlarm = call.argument<Boolean>("isAlarm") ?: false
                        val customPath = call.argument<String>("customPath")
                        playAestheticTone(soundId, isAlarm, customPath)
                        result.success(true)
                    }
                    "startFocusLoop" -> {
                        val soundId = call.argument<String>("soundId") ?: "rain"
                        val customPath = call.argument<String>("customPath")
                        val multiTrack = call.argument<Map<String, Double>>("multiTrack")
                        startFocusLoop(soundId, customPath, multiTrack)
                        result.success(true)
                    }
                    "stopFocusLoop" -> {
                        stopFocusLoop()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Initialize Notification Channels
        NotificationReceiver.createNotificationChannels(this)

        // 4. Native OS System Notifications & Exact Alarms Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                                != PackageManager.PERMISSION_GRANTED) {
                                ActivityCompat.requestPermissions(
                                    this,
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    POST_NOTIF_REQ
                                )
                                result.success(false)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "showNotification" -> {
                        val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                        val title = call.argument<String>("title") ?: "NOTtEodo"
                        val message = call.argument<String>("message") ?: ""
                        val channelId = call.argument<String>("channelId") ?: NotificationReceiver.CHANNEL_REMINDERS
                        showSystemNotification(id, title, message, channelId)
                        result.success(true)
                    }
                    "scheduleNotification" -> {
                        val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                        val title = call.argument<String>("title") ?: "NOTtEodo Reminder"
                        val message = call.argument<String>("message") ?: ""
                        val triggerTimeMillis = call.argument<Long>("triggerTimeMillis") ?: (System.currentTimeMillis() + 60000)
                        val channelId = call.argument<String>("channelId") ?: NotificationReceiver.CHANNEL_REMINDERS
                        scheduleSystemNotification(id, title, message, triggerTimeMillis, channelId)
                        result.success(true)
                    }
                    "cancelNotification" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancelSystemNotification(id)
                        result.success(true)
                    }
                    "updateFocusNotification" -> {
                        val soundTitle = call.argument<String>("soundTitle") ?: "Sanctuary Focus"
                        val remainingFormatted = call.argument<String>("remainingFormatted") ?: "25:00"
                        val isRunning = call.argument<Boolean>("isRunning") ?: true
                        val totalSeconds = call.argument<Int>("totalSeconds") ?: 1500
                        val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 1500
                        updateFocusNotification(soundTitle, remainingFormatted, isRunning, totalSeconds, remainingSeconds)
                        result.success(true)
                    }
                    "cancelFocusNotification" -> {
                        cancelFocusNotification()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 5. Native Google Calendar Intent / Web Bridge Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notteodo/calendar")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "addToCalendar" -> {
                        val title = call.argument<String>("title") ?: "Event"
                        val description = call.argument<String>("description")
                        val location = call.argument<String>("location")
                        val beginTimeMillis = call.argument<Long>("beginTimeMillis")
                        val endTimeMillis = call.argument<Long>("endTimeMillis")
                        val success = openCalendarEvent(title, description, location, beginTimeMillis, endTimeMillis)
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun showSystemNotification(id: Int, title: String, message: String, channelId: String) {
        NotificationReceiver.createNotificationChannels(this)
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, builder.build())
    }

    private fun scheduleSystemNotification(id: Int, title: String, message: String, triggerTimeMillis: Long, channelId: String) {
        NotificationReceiver.createNotificationChannels(this)
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_SHOW_NOTIFICATION
            putExtra("id", id)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("channelId", channelId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerTimeMillis, pendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
            }
        } catch (_: Exception) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerTimeMillis, pendingIntent)
                }
            } catch (_: Exception) {}
        }
    }

    private fun cancelSystemNotification(id: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(id)

        val intent = Intent(this, NotificationReceiver::class.java).apply {
            action = NotificationReceiver.ACTION_SHOW_NOTIFICATION
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
    }

    private fun openCalendarEvent(title: String, description: String?, location: String?, beginTimeMillis: Long?, endTimeMillis: Long?): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_INSERT).apply {
                data = CalendarContract.Events.CONTENT_URI
                putExtra(CalendarContract.Events.TITLE, title)
                if (description != null) putExtra(CalendarContract.Events.DESCRIPTION, description)
                if (location != null) putExtra(CalendarContract.Events.EVENT_LOCATION, location)
                if (beginTimeMillis != null) putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, beginTimeMillis)
                if (endTimeMillis != null) putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endTimeMillis)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                val gcalUrl = buildGCalUrl(title, description, location, beginTimeMillis, endTimeMillis)
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(gcalUrl))
                startActivity(webIntent)
                true
            }
        } catch (_: Exception) {
            val gcalUrl = buildGCalUrl(title, description, location, beginTimeMillis, endTimeMillis)
            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(gcalUrl))
            startActivity(webIntent)
            true
        }
    }

    private fun buildGCalUrl(title: String, description: String?, location: String?, beginMillis: Long?, endMillis: Long?): String {
        val sdf = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val start = if (beginMillis != null) sdf.format(Date(beginMillis)) else sdf.format(Date())
        val end = if (endMillis != null) sdf.format(Date(endMillis)) else sdf.format(Date(System.currentTimeMillis() + 3600000))
        val encTitle = URLEncoder.encode(title, "UTF-8")
        val encDesc = if (description != null) URLEncoder.encode(description, "UTF-8") else ""
        val encLoc = if (location != null) URLEncoder.encode(location, "UTF-8") else ""
        return "https://calendar.google.com/calendar/render?action=TEMPLATE&text=$encTitle&dates=$start/$end&details=$encDesc&location=$encLoc"
    }

    private fun startSpeechListening(result: MethodChannel.Result) {
        pendingSpeechResult = result
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak to NOTtEodo…")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        try {
            startActivityForResult(intent, SPEECH_ACTIVITY_REQ)
        } catch (_: Exception) {
            // Fallback to background SpeechRecognizer service
            startBackgroundSpeechRecognizer(result)
        }
    }

    private fun startBackgroundSpeechRecognizer(result: MethodChannel.Result) {
        runOnUiThread {
            try {
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onError(error: Int) {
                        try {
                            result.success(null)
                        } catch (_: Exception) {}
                    }
                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull()
                        try {
                            result.success(text)
                        } catch (_: Exception) {}
                    }
                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                speechRecognizer?.startListening(intent)
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SPEECH_ACTIVITY_REQ) {
            val res = pendingSpeechResult
            pendingSpeechResult = null
            if (resultCode == RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull()
                res?.success(text)
            } else {
                res?.success(null)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_REQ) {
            val res = pendingSpeechResult
            pendingSpeechResult = null
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (res != null) startSpeechListening(res)
            } else {
                res?.success(null)
            }
        }
    }

    private fun playAestheticTone(soundId: String, isAlarm: Boolean, customPath: String? = null) {
        thread(start = true, isDaemon = true) {
            try {
                // If custom user-uploaded file was chosen
                if (!customPath.isNullOrEmpty()) {
                    val file = java.io.File(customPath)
                    if (file.exists()) {
                        val player = android.media.MediaPlayer().apply {
                            setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                    .build()
                            )
                            setDataSource(customPath)
                            prepare()
                            start()
                            setOnCompletionListener { mp -> mp.release() }
                        }
                        return@thread
                    }
                }

                val sampleRate = 44100
                val durationMs = when (soundId) {
                    "minimalist_ping" -> 90
                    "analog_switch" -> 110
                    "velvet_obsidian" -> 350
                    "celestial_shimmer" -> 480
                    "zen_bloom" -> 680
                    "terracotta_pulse" -> 320
                    "golden_dawn" -> 580
                    "architect_echo" -> 620
                    "starlight_aura" -> 640
                    "horology_cascade" -> 520
                    else -> 320
                }

                val numSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                val samples = ShortArray(numSamples)

                for (i in 0 until numSamples) {
                    val t = i.toDouble() / sampleRate
                    val progress = i.toDouble() / numSamples

                    val wave = when (soundId) {
                        // 1. Velvet Obsidian: Warm wooden marimba (440Hz + 880Hz octave)
                        "velvet_obsidian" -> {
                            val decay = exp(-progress * 7.5)
                            (0.7 * sin(2.0 * PI * 440.0 * t) + 0.3 * sin(2.0 * PI * 880.0 * t)) * decay
                        }
                        // 2. Celestial Shimmer: Crystal harmonics (1046Hz + 1318Hz + 1568Hz)
                        "celestial_shimmer" -> {
                            val decay = exp(-progress * 5.5)
                            (0.45 * sin(2.0 * PI * 1046.5 * t) +
                             0.35 * sin(2.0 * PI * 1318.5 * t) +
                             0.20 * sin(2.0 * PI * 1567.98 * t)) * decay
                        }
                        // 3. Minimalist Ping: Pure ultra-crisp micro drop (1760Hz)
                        "minimalist_ping" -> {
                            val decay = exp(-progress * 16.0)
                            sin(2.0 * PI * 1760.0 * t) * decay
                        }
                        // 4. Analog Switch: Mechanical switch transient + resonant bottom pad
                        "analog_switch" -> {
                            val click = if (t < 0.015) sin(2.0 * PI * 2400.0 * t) * 0.7 else 0.0
                            val body = sin(2.0 * PI * 140.0 * t) * exp(-progress * 12.0) * 0.5
                            click + body
                        }
                        // 5. Zen Bloom: Bronze singing bowl (528Hz + 1056Hz overtone)
                        "zen_bloom" -> {
                            val decay = exp(-progress * 4.0)
                            (0.75 * sin(2.0 * PI * 528.0 * t) + 0.25 * sin(2.0 * PI * 1056.0 * t)) * decay
                        }
                        // 6. Horology Cascade: Swiss watch escapement tick ending in bell chime
                        "horology_cascade" -> {
                            val tickPhase = (t * 12.0) % 1.0
                            val tick = if (t < 0.35 && tickPhase < 0.1) sin(2.0 * PI * 1800.0 * t) * 0.6 else 0.0
                            val chime = if (t >= 0.2) sin(2.0 * PI * 880.0 * (t - 0.2)) * exp(-(t - 0.2) * 7.0) * 0.7 else 0.0
                            tick + chime
                        }
                        // 7. Sunrise Swell / Golden Dawn: Warm analog triad swell (E - G# - B: 330, 415, 494 Hz)
                        "golden_dawn" -> {
                            val envelope = if (progress < 0.3) progress / 0.3 else exp(-(progress - 0.3) * 4.5)
                            (0.4 * sin(2.0 * PI * 329.63 * t) +
                             0.35 * sin(2.0 * PI * 415.30 * t) +
                             0.25 * sin(2.0 * PI * 493.88 * t)) * envelope
                        }
                        // 8. Terracotta Pulse: Warm 220Hz resonant low-percussion pulse
                        "terracotta_pulse" -> {
                            val pitchDecay = 220.0 * exp(-progress * 2.8)
                            val decay = exp(-progress * 8.5)
                            sin(2.0 * PI * pitchDecay * t) * decay
                        }
                        // 9. Architect Echo: Deep resonant temple gong (180Hz + 360Hz)
                        "architect_echo" -> {
                            val decay = exp(-progress * 3.8)
                            (0.7 * sin(2.0 * PI * 180.0 * t) + 0.3 * sin(2.0 * PI * 360.0 * t)) * decay
                        }
                        // 10. Starlight Aura: Harp arpeggio sequence (523, 659, 784, 1046 Hz)
                        "starlight_aura" -> {
                            val step = (progress * 4.0).toInt().coerceIn(0, 3)
                            val freq = when (step) {
                                0 -> 523.25
                                1 -> 659.25
                                2 -> 783.99
                                else -> 1046.50
                            }
                            val decay = exp(-((progress * 4.0) - step) * 4.5)
                            sin(2.0 * PI * freq * t) * decay * 0.85
                        }
                        else -> sin(2.0 * PI * 587.33 * t) * exp(-progress * 7.5)
                    }

                    // Soft clip and map to 16-bit PCM amplitude for clear, loud playback
                    val clamped = wave.coerceIn(-1.0, 1.0)
                    samples[i] = (clamped * 32000.0).toInt().toShort()
                }

                // Use USAGE_MEDIA so audio plays audibly through the device media stream
                // regardless of whether notification ringer is set to vibrate/silent
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(samples.size * 2)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()

                track.write(samples, 0, samples.size)
                track.play()

                // Clean up track after completion
                Thread.sleep(durationMs.toLong() + 150)
                try {
                    track.stop()
                    track.release()
                } catch (_: Exception) {}
            } catch (_: Exception) {}
        }
    }

    private var focusLoopTrack: AudioTrack? = null
    private var focusLoopPlayer: android.media.MediaPlayer? = null

    private fun stopFocusLoop() {
        try {
            focusLoopTrack?.let {
                if (it.playState == AudioTrack.PLAYSTATE_PLAYING) it.stop()
                it.release()
            }
        } catch (_: Exception) {}
        focusLoopTrack = null

        try {
            focusLoopPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {}
        focusLoopPlayer = null
    }

    private fun startFocusLoop(soundId: String, customPath: String? = null, multiTrack: Map<String, Double>? = null) {
        stopFocusLoop()
        if (soundId == "none" || soundId == "mute") return

        thread(start = true, isDaemon = true) {
            try {
                if (!customPath.isNullOrEmpty()) {
                    val file = java.io.File(customPath)
                    if (file.exists()) {
                        focusLoopPlayer = android.media.MediaPlayer().apply {
                            setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_MEDIA)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                    .build()
                            )
                            setDataSource(customPath)
                            isLooping = true
                            prepare()
                            start()
                        }
                        return@thread
                    }
                }

                // Native looping sound synthesis (seamless 3-second loop buffer with AudioTrack loop points)
                val sampleRate = 22050
                val durationSec = 3.0
                val numSamples = (sampleRate * durationSec).toInt()
                val samples = ShortArray(numSamples)

                val rainVol = multiTrack?.get("rain") ?: (if (soundId == "rain") 1.0 else 0.0)
                val zenVol = multiTrack?.get("zen_drone") ?: (if (soundId == "zen_drone") 1.0 else 0.0)
                val windVol = multiTrack?.get("forest_wind") ?: (if (soundId == "forest_wind") 1.0 else 0.0)
                val bowlVol = multiTrack?.get("singing_bowl") ?: (if (soundId == "singing_bowl") 1.0 else 0.0)
                val fireVol = multiTrack?.get("campfire") ?: (if (soundId == "campfire") 1.0 else 0.0)

                val random = java.util.Random(42)
                for (i in 0 until numSamples) {
                    val t = i.toDouble() / sampleRate

                    val rainNoise = (random.nextDouble() * 2.0 - 1.0) * 0.22
                    val rainDrop = if (random.nextDouble() < 0.003) sin(2.0 * PI * (800.0 + random.nextDouble() * 400.0) * t) * 0.15 else 0.0
                    val rainWave = (rainNoise + rainDrop) * rainVol

                    val zenWave = (0.45 * sin(2.0 * PI * 108.0 * t) +
                                   0.25 * sin(2.0 * PI * 216.0 * t) +
                                   0.12 * sin(2.0 * PI * 432.0 * t) +
                                   0.08 * sin(2.0 * PI * 54.0 * t)) * zenVol

                    val slowLfo = 0.5 + 0.5 * sin(2.0 * PI * 0.33 * t)
                    val breeze = (random.nextDouble() * 2.0 - 1.0) * 0.12 * slowLfo
                    val tone = sin(2.0 * PI * (196.0 + 20.0 * sin(2.0 * PI * 0.2 * t)) * t) * 0.18 * slowLfo
                    val windWave = (breeze + tone) * windVol

                    val beat = 0.7 + 0.3 * sin(2.0 * PI * 1.5 * t)
                    val bowlWave = ((0.55 * sin(2.0 * PI * 432.0 * t) + 0.25 * sin(2.0 * PI * 864.0 * t)) * beat) * bowlVol

                    val rumble = sin(2.0 * PI * 75.0 * t) * 0.15 + (random.nextDouble() * 2.0 - 1.0) * 0.08
                    val crackle = if (random.nextDouble() < 0.006) (random.nextDouble() * 2.0 - 1.0) * 0.55 else 0.0
                    val fireWave = (rumble + crackle) * fireVol

                    val rawWave = rainWave + zenWave + windWave + bowlWave + fireWave

                    val edgeSamples = (sampleRate * 0.05).toInt()
                    val window = if (i < edgeSamples) {
                        i.toDouble() / edgeSamples
                    } else if (i > numSamples - edgeSamples) {
                        (numSamples - i).toDouble() / edgeSamples
                    } else 1.0

                    val clamped = (rawWave * window).coerceIn(-1.0, 1.0)
                    samples[i] = (clamped * 24000.0).toInt().toShort()
                }

                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(samples.size * 2)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()

                track.write(samples, 0, samples.size)
                track.setLoopPoints(0, numSamples, -1)
                track.play()
                focusLoopTrack = track
            } catch (_: Exception) {}
        }
    }

    private fun pauseFocusLoop() {
        try {
            focusLoopPlayer?.pause()
        } catch (_: Exception) {}
        try {
            if (focusLoopTrack?.playState == AudioTrack.PLAYSTATE_PLAYING) {
                focusLoopTrack?.pause()
            }
        } catch (_: Exception) {}
    }

    private fun resumeFocusLoop() {
        try {
            focusLoopPlayer?.start()
        } catch (_: Exception) {}
        try {
            if (focusLoopTrack?.playState == AudioTrack.PLAYSTATE_PAUSED) {
                focusLoopTrack?.play()
            }
        } catch (_: Exception) {}
    }

    fun onFocusActionReceived(action: String) {
        runOnUiThread {
            when (action) {
                "pause" -> pauseFocusLoop()
                "resume" -> resumeFocusLoop()
                "stop" -> {
                    stopFocusLoop()
                    cancelFocusNotification()
                }
            }
            focusActionChannel?.invokeMethod("onFocusAction", mapOf("action" to action))
        }
    }

    private fun updateFocusNotification(
        soundTitle: String,
        remainingFormatted: String,
        isRunning: Boolean,
        totalSeconds: Int,
        remainingSeconds: Int
    ) {
        try {
            val openIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val contentPendingIntent = PendingIntent.getActivity(
                this,
                FOCUS_NOTIFICATION_ID,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val pauseIntent = Intent(this, NotificationReceiver::class.java).apply {
                action = NotificationReceiver.ACTION_FOCUS_PAUSE
            }
            val pausePending = PendingIntent.getBroadcast(
                this,
                8801,
                pauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val resumeIntent = Intent(this, NotificationReceiver::class.java).apply {
                action = NotificationReceiver.ACTION_FOCUS_RESUME
            }
            val resumePending = PendingIntent.getBroadcast(
                this,
                8802,
                resumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val stopIntent = Intent(this, NotificationReceiver::class.java).apply {
                action = NotificationReceiver.ACTION_FOCUS_STOP
            }
            val stopPending = PendingIntent.getBroadcast(
                this,
                8803,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val soundLabel = if (soundTitle.isNotEmpty() && soundTitle != "none" && soundTitle != "Silent Focus") {
                "🎧 $soundTitle"
            } else {
                "🕯️ Silent sanctuary focus"
            }

            val builder = NotificationCompat.Builder(this, NotificationReceiver.CHANNEL_FOCUS)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(if (isRunning) "Focus Session · $remainingFormatted remaining" else "Focus Paused · $remainingFormatted")
                .setContentText(soundLabel)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(isRunning)
                .setOnlyAlertOnce(true)
                .setProgress(totalSeconds, totalSeconds - remainingSeconds, false)
                .setContentIntent(contentPendingIntent)

            if (isRunning) {
                builder.addAction(android.R.drawable.ic_media_pause, "Pause", pausePending)
            } else {
                builder.addAction(android.R.drawable.ic_media_play, "Resume", resumePending)
            }
            builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPending)

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(FOCUS_NOTIFICATION_ID, builder.build())
        } catch (_: Exception) {}
    }

    private fun cancelFocusNotification() {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(FOCUS_NOTIFICATION_ID)
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        if (instance == this) instance = null
        stopFocusLoop()
        cancelFocusNotification()
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
