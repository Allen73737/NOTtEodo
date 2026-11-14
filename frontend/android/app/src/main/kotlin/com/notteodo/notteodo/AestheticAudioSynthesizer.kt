package com.notteodo.notteodo

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.MediaPlayer
import java.io.File
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

/**
 * Shared aesthetic DSP audio synthesizer for NOTtEodo.
 *
 * Synthesizes pure 16-bit PCM waveforms at 44.1kHz across 10 luxury Tuscan soundscapes
 * (5 notification presets, 5 alarm/reminder presets), plus custom user audio playback.
 * Invoked by both [MainActivity] and background [NotificationReceiver] when alarms/timers fire.
 */
object AestheticAudioSynthesizer {
    private const val PREFS_FLUTTER = "FlutterSharedPreferences"
    private const val PREFS_NOTTEODO = "notteodo_prefs"

    fun getSavedAlarmSound(context: Context): Pair<String, String?> {
        val nPrefs = context.getSharedPreferences(PREFS_NOTTEODO, Context.MODE_PRIVATE)
        var sound = nPrefs.getString("alarmSound", null)
        var path = nPrefs.getString("customAlarmSoundPath", null)

        if (sound.isNullOrEmpty()) {
            val fPrefs = context.getSharedPreferences(PREFS_FLUTTER, Context.MODE_PRIVATE)
            sound = fPrefs.getString("flutter.alarmSound", "horology_cascade")
            path = fPrefs.getString("flutter.customAlarmSoundPath", null)
        }
        return Pair(sound ?: "horology_cascade", path)
    }

    fun getSavedNotificationSound(context: Context): Pair<String, String?> {
        val nPrefs = context.getSharedPreferences(PREFS_NOTTEODO, Context.MODE_PRIVATE)
        var sound = nPrefs.getString("notificationSound", null)
        var path = nPrefs.getString("customNotificationSoundPath", null)

        if (sound.isNullOrEmpty()) {
            val fPrefs = context.getSharedPreferences(PREFS_FLUTTER, Context.MODE_PRIVATE)
            sound = fPrefs.getString("flutter.notificationSound", "velvet_obsidian")
            path = fPrefs.getString("flutter.customNotificationSoundPath", null)
        }
        return Pair(sound ?: "velvet_obsidian", path)
    }

    fun playAestheticTone(
        context: Context?,
        soundId: String,
        isAlarm: Boolean = false,
        customPath: String? = null
    ) {
        thread(start = true, isDaemon = true) {
            try {
                // 1. Play custom audio file if provided
                if (!customPath.isNullOrEmpty()) {
                    val file = File(customPath)
                    if (file.exists()) {
                        val player = MediaPlayer().apply {
                            setAudioAttributes(
                                AudioAttributes.Builder()
                                    .setUsage(if (isAlarm) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_MEDIA)
                                    .setContentType(if (isAlarm) AudioAttributes.CONTENT_TYPE_SONIFICATION else AudioAttributes.CONTENT_TYPE_MUSIC)
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

                // 2. Synthesize Tuscan Luxury DSP acoustic waveform (44.1kHz mono)
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
                    else -> 380
                }

                val singleCycleSamples = (sampleRate * (durationMs / 1000.0)).toInt()
                // For alarms and cadence completion, repeat the sonic motif twice for clear audibility
                val cycles = if (isAlarm) 2 else 1
                val pauseSamples = if (isAlarm) (sampleRate * 0.12).toInt() else 0
                val totalSamples = (singleCycleSamples * cycles) + (pauseSamples * (cycles - 1))
                val samples = ShortArray(totalSamples)

                for (c in 0 until cycles) {
                    val cycleOffset = c * (singleCycleSamples + pauseSamples)
                    for (i in 0 until singleCycleSamples) {
                        val t = i.toDouble() / sampleRate
                        val progress = i.toDouble() / singleCycleSamples

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

                        val clamped = wave.coerceIn(-1.0, 1.0)
                        samples[cycleOffset + i] = (clamped * 32000.0).toInt().toShort()
                    }
                }

                // 3. Play through AudioTrack
                val track = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(if (isAlarm) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_MEDIA)
                            .setContentType(if (isAlarm) AudioAttributes.CONTENT_TYPE_SONIFICATION else AudioAttributes.CONTENT_TYPE_MUSIC)
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

                val totalWaitMs = (durationMs * cycles) + (if (cycles > 1) 120 else 0) + 160
                Thread.sleep(totalWaitMs.toLong())
                try {
                    track.stop()
                    track.release()
                } catch (_: Exception) {}
            } catch (_: Exception) {}
        }
    }
}

