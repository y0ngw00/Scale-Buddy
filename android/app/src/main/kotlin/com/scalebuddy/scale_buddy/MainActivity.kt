package com.scalebuddy.scale_buddy

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.PI
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val audioLock = Any()
    private var activeAudioTrack: AudioTrack? = null
    private var playbackThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scale_buddy/audio"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playTone" -> {
                    val frequency = call.argument<Double>("frequency") ?: 440.0
                    val durationMs = call.argument<Int>("durationMs") ?: 400
                    playTone(frequency, durationMs)
                    result.success(null)
                }
                "stop" -> {
                    stopTone()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playTone(frequency: Double, durationMs: Int) {
        stopTone()

        val worker = thread(start = true, name = "ScaleBuddyTone") {
            val sampleRate = 44100
            val sampleCount = sampleRate * durationMs / 1000
            val buffer = ShortArray(sampleCount)
            val fadeSamples = minOf(sampleRate / 100, sampleCount / 2)

            for (index in buffer.indices) {
                val fadeIn = if (fadeSamples == 0) 1.0 else (index.toDouble() / fadeSamples).coerceAtMost(1.0)
                val fadeOut = if (fadeSamples == 0) 1.0 else ((buffer.size - index).toDouble() / fadeSamples).coerceAtMost(1.0)
                val envelope = minOf(fadeIn, fadeOut)
                val wave = sin(2.0 * PI * index * frequency / sampleRate)
                buffer[index] = (wave * envelope * Short.MAX_VALUE * 0.28).toInt().toShort()
            }

            val audioTrack = AudioTrack.Builder()
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
                .setBufferSizeInBytes(buffer.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            try {
                synchronized(audioLock) {
                    activeAudioTrack = audioTrack
                }

                audioTrack.write(buffer, 0, buffer.size)
                audioTrack.play()
                Thread.sleep(durationMs.toLong())
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            } catch (_: IllegalStateException) {
                // The track may already be stopped when the user taps Stop quickly.
            } finally {
                releaseTrack(audioTrack)
                synchronized(audioLock) {
                    if (activeAudioTrack === audioTrack) {
                        activeAudioTrack = null
                    }
                    if (playbackThread === Thread.currentThread()) {
                        playbackThread = null
                    }
                }
            }
        }

        synchronized(audioLock) {
            playbackThread = worker
        }
    }

    private fun stopTone() {
        val threadToStop: Thread?
        val trackToStop: AudioTrack?

        synchronized(audioLock) {
            threadToStop = playbackThread
            trackToStop = activeAudioTrack
            playbackThread = null
            activeAudioTrack = null
        }

        threadToStop?.interrupt()
        trackToStop?.let { releaseTrack(it) }
    }

    private fun releaseTrack(audioTrack: AudioTrack) {
        try {
            audioTrack.pause()
            audioTrack.flush()
        } catch (_: IllegalStateException) {
            // Ignore tracks that were already stopped or not fully initialized.
        } finally {
            try {
                audioTrack.release()
            } catch (_: IllegalStateException) {
                // Ignore duplicate release attempts during rapid note changes.
            }
        }
    }
}
