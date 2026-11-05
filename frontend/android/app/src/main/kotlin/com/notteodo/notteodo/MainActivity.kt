package com.notteodo.notteodo

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterFragmentActivity() {
    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingSpeechResult: MethodChannel.Result? = null
    private val RECORD_AUDIO_REQ = 2001
    private val SPEECH_ACTIVITY_REQ = 2002

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    else -> result.notImplemented()
                }
            }
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

    override fun onDestroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
