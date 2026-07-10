package com.mobileway.ui_clone.capture

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.DisplayMetrics
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import com.mobileway.ui_clone.MainActivity
import com.mobileway.ui_clone.R
import com.mobileway.ui_clone.overlay.CaptureOverlayService
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

class ScreenCaptureService : Service() {
    companion object {
        const val ACTION_START = "com.mobileway.ui_clone.capture.START"
        const val ACTION_STOP = "com.mobileway.ui_clone.capture.STOP"
        const val ACTION_SHOT = "com.mobileway.ui_clone.capture.SHOT"
        const val ACTION_TOGGLE_PAUSE = "com.mobileway.ui_clone.capture.TOGGLE_PAUSE"
        const val ACTION_PAUSE = "com.mobileway.ui_clone.capture.PAUSE"
        const val ACTION_RESUME = "com.mobileway.ui_clone.capture.RESUME"
        const val ACTION_FOREGROUND = "com.mobileway.ui_clone.capture.FOREGROUND"
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_RESULT_DATA = "resultData"
        const val EXTRA_SESSION_ID = "sessionId"
        const val EXTRA_TARGET_PACKAGE = "targetPackage"
        const val EXTRA_TARGET_LABEL = "targetLabel"
        const val EXTRA_INTERVAL_MS = "intervalMs"
        const val EXTRA_SIMILARITY_PERCENT = "similarityPercent"
        /** timer | manual | both */
        const val EXTRA_CAPTURE_MODE = "captureMode"
        const val EXTRA_MAX_DURATION_MS = "maxDurationMs"
        const val EXTRA_WARN_BEFORE_MS = "warnBeforeMs"
        const val EXTRA_OWN_APP_FOREGROUND = "ownAppForeground"

        private const val CHANNEL_ID = "ui_clone_capture"
        private const val NOTIFICATION_ID = 7101
        private const val MAX_SHOTS = 40
        private const val DEFAULT_MAX_DURATION_MS = 300_000L
        private const val DEFAULT_WARN_BEFORE_MS = 30_000L
        /** Delay after detaching overlay before grabbing a frame. */
        private const val OVERLAY_HIDE_MS = 120L
        /** Extra time to wait for a VirtualDisplay frame after overlay detach. */
        private const val FRAME_POLL_MS = 280L

        @Volatile
        private var instance: ScreenCaptureService? = null

        private val collectedPaths = CopyOnWriteArrayList<String>()

        fun requestStop(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun requestShot(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_SHOT
            }
            context.startService(intent)
        }

        fun requestTogglePause(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_TOGGLE_PAUSE
            }
            context.startService(intent)
        }

        fun requestPause(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_PAUSE
            }
            context.startService(intent)
        }

        fun requestResume(context: Context) {
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_RESUME
            }
            context.startService(intent)
        }

        fun notifyOwnAppForeground(context: Context, foreground: Boolean) {
            AppForegroundTracker.setOwnAppForeground(foreground)
            val intent = Intent(context, ScreenCaptureService::class.java).apply {
                action = ACTION_FOREGROUND
                putExtra(EXTRA_OWN_APP_FOREGROUND, foreground)
            }
            // startService is fine even if capture isn't running — onStartCommand
            // no-ops when not capturing.
            try {
                context.startService(intent)
            } catch (_: Exception) {
            }
        }

        fun stopAndCollect(context: Context): List<String> {
            // Do not sleep on the binder/UI thread — it freezes Flutter frames
            // so the "stopping" button state never paints.
            val snapshot = collectedPaths.toList()
            requestStop(context)
            return snapshot
        }
    }

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null
    private var captureRunnable: Runnable? = null
    private var sessionTickRunnable: Runnable? = null

    private var sessionId: String = ""
    private var targetPackage: String? = null
    private var targetLabel: String? = null
    private var intervalMs: Long = 1500L
    /** timer | manual | both */
    private var captureMode: String = "timer"
    private var maxDurationMs: Long = DEFAULT_MAX_DURATION_MS
    private var warnBeforeMs: Long = DEFAULT_WARN_BEFORE_MS
    private var sessionDeadlineElapsed: Long = 0L
    private var pauseStartedElapsed: Long = 0L
    private var timeWarningEmitted = false
    private var width = 0
    private var height = 0
    private var density = 0

    private val isCapturing = AtomicBoolean(false)
    private val isPaused = AtomicBoolean(false)
    private val isSaving = AtomicBoolean(false)
    private var similarityGate = FrameSimilarityGate()
    private var ownAppSkipCount = 0
    private var lastOwnAppEmitElapsed = 0L
    private var targetMismatchSkipCount = 0
    private var lastTargetMismatchEmitElapsed = 0L
    private var lastKnownForegroundPackage: String? = null

    private val allowsTimer: Boolean
        get() = captureMode == "timer" || captureMode == "both"

    private val allowsManual: Boolean
        get() = captureMode == "manual" || captureMode == "both"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        handlerThread = HandlerThread("ui_clone-capture").also { it.start() }
        handler = Handler(handlerThread!!.looper)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                finalizeCapture()
                stopSelf()
            }
            ACTION_SHOT -> {
                if (isCapturing.get() && allowsManual) {
                    handler?.post { captureFrame(forceKeep = true) }
                }
            }
            ACTION_TOGGLE_PAUSE -> {
                if (!isCapturing.get()) return START_STICKY
                if (isPaused.get()) resumeCapture() else pauseCapture()
            }
            ACTION_PAUSE -> {
                if (isCapturing.get()) pauseCapture()
            }
            ACTION_RESUME -> {
                if (isCapturing.get()) resumeCapture()
            }
            ACTION_FOREGROUND -> {
                if (!isCapturing.get()) return START_STICKY
                val foreground = intent.getBooleanExtra(EXTRA_OWN_APP_FOREGROUND, false)
                onOwnAppForegroundChanged(foreground)
            }
            ACTION_START -> startCapture(intent)
        }
        return START_STICKY
    }

    private fun startCapture(intent: Intent) {
        if (isCapturing.get()) return

        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
        val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_RESULT_DATA)
        }
        if (data == null) {
            CaptureEventBus.emit(
                mapOf("type" to "error", "message" to "Missing MediaProjection data"),
            )
            stopSelf()
            return
        }

        sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: ""
        targetPackage = intent.getStringExtra(EXTRA_TARGET_PACKAGE)
        targetLabel = intent.getStringExtra(EXTRA_TARGET_LABEL)
        intervalMs = intent.getLongExtra(EXTRA_INTERVAL_MS, 1500L).coerceIn(800L, 5000L)
        captureMode = when (intent.getStringExtra(EXTRA_CAPTURE_MODE)) {
            "manual" -> "manual"
            "both" -> "both"
            else -> "timer"
        }
        maxDurationMs = intent
            .getLongExtra(EXTRA_MAX_DURATION_MS, DEFAULT_MAX_DURATION_MS)
            .coerceIn(60_000L, 900_000L)
        warnBeforeMs = intent
            .getLongExtra(EXTRA_WARN_BEFORE_MS, DEFAULT_WARN_BEFORE_MS)
            .coerceIn(5_000L, maxDurationMs / 2)
        val similarityPercent = intent
            .getFloatExtra(EXTRA_SIMILARITY_PERCENT, FrameSimilarityGate.DEFAULT_MAX_DIFF_PERCENT)
            .coerceIn(0.5f, 15f)
        similarityGate = FrameSimilarityGate(maxDiffPercent = similarityPercent)
        similarityGate.reset()

        collectedPaths.clear()
        resolveDisplayMetrics()

        val notification = buildNotification(0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mpm.getMediaProjection(resultCode, data)
        mediaProjection?.registerCallback(
            object : MediaProjection.Callback() {
                override fun onStop() {
                    finalizeCapture()
                    stopSelf()
                }
            },
            handler,
        )

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 3)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ui_clone-vd",
            width,
            height,
            density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            handler,
        )

        isCapturing.set(true)
        isPaused.set(false)
        timeWarningEmitted = false
        ownAppSkipCount = 0
        lastOwnAppEmitElapsed = 0L
        targetMismatchSkipCount = 0
        lastTargetMismatchEmitElapsed = 0L
        lastKnownForegroundPackage = null
        sessionDeadlineElapsed = SystemClock.elapsedRealtime() + maxDurationMs
        refreshChrome(0)
        CaptureEventBus.emit(
            mapOf(
                "type" to "started",
                "sessionId" to sessionId,
                "targetLabel" to targetLabel,
                "targetPackage" to targetPackage,
                "captureMode" to captureMode,
                "remainingSec" to (maxDurationMs / 1000L).toInt(),
                "maxDurationSec" to (maxDurationMs / 1000L).toInt(),
                "ownAppForeground" to AppForegroundTracker.isOwnAppForeground,
                "usageAccessGranted" to ForegroundAppHelper.canTrackForeground(this),
            ),
        )

        startTimerLoop(initialDelayMs = 600L)
        startSessionClock()
        // Sync current foreground state (user may still be in UI Clone).
        onOwnAppForegroundChanged(AppForegroundTracker.isOwnAppForeground)
    }

    private fun onOwnAppForegroundChanged(foreground: Boolean) {
        AppForegroundTracker.setOwnAppForeground(foreground)
        CaptureEventBus.emit(
            mapOf(
                "type" to "own_app_foreground",
                "active" to foreground,
                "count" to collectedPaths.size,
                "ownAppSkipped" to ownAppSkipCount,
            ),
        )
        refreshChrome(collectedPaths.size)
    }

    private fun startTimerLoop(initialDelayMs: Long = intervalMs) {
        if (!allowsTimer) return
        captureRunnable?.let { handler?.removeCallbacks(it) }
        val runnable = object : Runnable {
            override fun run() {
                if (!isCapturing.get()) return
                if (!isPaused.get()) {
                    captureFrame(forceKeep = false)
                }
                handler?.postDelayed(this, intervalMs)
            }
        }
        captureRunnable = runnable
        handler?.postDelayed(runnable, initialDelayMs)
    }

    private fun startSessionClock() {
        cancelSessionClock()
        val tick = object : Runnable {
            override fun run() {
                if (!isCapturing.get()) return
                if (isPaused.get()) {
                    handler?.postDelayed(this, 1000L)
                    return
                }
                val remainingMs =
                    (sessionDeadlineElapsed - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
                val remainingSec = (remainingMs / 1000L).toInt()
                CaptureEventBus.emit(
                    mapOf(
                        "type" to "time_tick",
                        "remainingSec" to remainingSec,
                        "count" to collectedPaths.size,
                    ),
                )
                if (remainingMs <= warnBeforeMs && !timeWarningEmitted) {
                    timeWarningEmitted = true
                    CaptureEventBus.emit(
                        mapOf(
                            "type" to "time_warning",
                            "remainingSec" to remainingSec,
                            "count" to collectedPaths.size,
                        ),
                    )
                    refreshChrome(collectedPaths.size)
                }
                if (remainingMs <= 0L) {
                    CaptureEventBus.emit(
                        mapOf(
                            "type" to "time_limit",
                            "remainingSec" to 0,
                            "count" to collectedPaths.size,
                        ),
                    )
                    finalizeCapture(stopReason = "time_limit")
                    stopSelf()
                    return
                }
                if (remainingMs <= warnBeforeMs || remainingSec % 15 == 0) {
                    refreshChrome(collectedPaths.size)
                }
                handler?.postDelayed(this, 1000L)
            }
        }
        sessionTickRunnable = tick
        handler?.post(tick)
    }

    private fun cancelSessionClock() {
        sessionTickRunnable?.let { handler?.removeCallbacks(it) }
        sessionTickRunnable = null
    }

    private fun remainingSecNow(): Int {
        if (sessionDeadlineElapsed <= 0L) {
            return (maxDurationMs / 1000L).toInt()
        }
        val remainingMs =
            (sessionDeadlineElapsed - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
        return (remainingMs / 1000L).toInt()
    }

    private fun pauseCapture() {
        if (!isCapturing.get() || isPaused.getAndSet(true)) return
        pauseStartedElapsed = SystemClock.elapsedRealtime()
        captureRunnable?.let { handler?.removeCallbacks(it) }
        refreshChrome(collectedPaths.size)
        CaptureEventBus.emit(
            mapOf(
                "type" to "paused",
                "count" to collectedPaths.size,
                "skipped" to similarityGate.skippedCount(),
                "remainingSec" to remainingSecNow(),
            ),
        )
    }

    private fun resumeCapture() {
        if (!isCapturing.get() || !isPaused.getAndSet(false)) return
        if (pauseStartedElapsed > 0L) {
            val pausedFor = SystemClock.elapsedRealtime() - pauseStartedElapsed
            sessionDeadlineElapsed += pausedFor
            pauseStartedElapsed = 0L
        }
        refreshChrome(collectedPaths.size)
        CaptureEventBus.emit(
            mapOf(
                "type" to "resumed",
                "count" to collectedPaths.size,
                "skipped" to similarityGate.skippedCount(),
                "remainingSec" to remainingSecNow(),
            ),
        )
        startTimerLoop(initialDelayMs = 300L)
    }

    private fun refreshChrome(count: Int) {
        updateNotification(count)
        CaptureOverlayService.update(
            this,
            count,
            showShotButton = allowsManual,
            paused = isPaused.get(),
        )
    }

    private fun captureFrame(forceKeep: Boolean = false) {
        if (!isCapturing.get() || isSaving.get()) return
        // Auto frames respect pause; forced manual shots do not.
        if (!forceKeep && isPaused.get()) return
        // Never save frames of UI Clone itself (timer or manual).
        if (AppForegroundTracker.isOwnAppForeground) {
            ownAppSkipCount++
            val now = SystemClock.elapsedRealtime()
            if (now - lastOwnAppEmitElapsed >= 1500L) {
                lastOwnAppEmitElapsed = now
                CaptureEventBus.emit(
                    mapOf(
                        "type" to "own_app_skipped",
                        "ownAppSkipped" to ownAppSkipCount,
                        "count" to collectedPaths.size,
                    ),
                )
            }
            return
        }
        // When a target app was selected, only keep frames while that package
        // is positively in the foreground. Fail closed without tracking
        // permission and when current app != target (home / other).
        val target = targetPackage
        if (!target.isNullOrBlank()) {
            if (!ForegroundAppHelper.canTrackForeground(this)) {
                targetMismatchSkipCount++
                val now = SystemClock.elapsedRealtime()
                if (now - lastTargetMismatchEmitElapsed >= 1500L) {
                    lastTargetMismatchEmitElapsed = now
                    CaptureEventBus.emit(
                        mapOf(
                            "type" to "target_mismatch",
                            "targetPackage" to target,
                            "currentPackage" to null,
                            "currentLabel" to "нужен доступ Accessibility",
                            "targetMismatchSkipped" to targetMismatchSkipCount,
                            "count" to collectedPaths.size,
                            "usageAccessGranted" to false,
                        ),
                    )
                    refreshChrome(collectedPaths.size)
                }
                return
            }
            val current = ForegroundAppHelper.currentForegroundPackage(this)
            lastKnownForegroundPackage = current
            if (current != target) {
                targetMismatchSkipCount++
                val now = SystemClock.elapsedRealtime()
                if (now - lastTargetMismatchEmitElapsed >= 1500L) {
                    lastTargetMismatchEmitElapsed = now
                    val label = when {
                        current.isNullOrBlank() -> "домашний экран / другое"
                        else -> ForegroundAppHelper.labelForPackage(this, current)
                    }
                    CaptureEventBus.emit(
                        mapOf(
                            "type" to "target_mismatch",
                            "targetPackage" to target,
                            "currentPackage" to current,
                            "currentLabel" to label,
                            "targetMismatchSkipped" to targetMismatchSkipCount,
                            "count" to collectedPaths.size,
                            "usageAccessGranted" to true,
                        ),
                    )
                    refreshChrome(collectedPaths.size)
                }
                return
            }
            if (targetMismatchSkipCount > 0) {
                targetMismatchSkipCount = 0
                CaptureEventBus.emit(
                    mapOf(
                        "type" to "target_match",
                        "targetPackage" to target,
                        "currentPackage" to current,
                        "count" to collectedPaths.size,
                    ),
                )
                refreshChrome(collectedPaths.size)
            }
        }
        if (collectedPaths.size >= MAX_SHOTS) {
            finalizeCapture()
            stopSelf()
            return
        }

        if (!isSaving.compareAndSet(false, true)) return

        // Hide floating controls so MediaProjection does not bake them into the shot.
        // Overlay WindowManager updates must run on the main thread; otherwise the
        // panel can reappear visually but stop receiving touches, and isSaving can stick.
        val captureHandler = handler
        if (captureHandler == null) {
            isSaving.set(false)
            return
        }
        Handler(Looper.getMainLooper()).post {
            if (!isCapturing.get()) {
                isSaving.set(false)
                return@post
            }
            try {
                CaptureOverlayService.setHiddenForCapture(true)
            } catch (_: Exception) {
                isSaving.set(false)
                return@post
            }
            captureHandler.postDelayed({
                try {
                    grabFrameAfterOverlayHidden(forceKeep)
                } finally {
                    Handler(Looper.getMainLooper()).post {
                        CaptureOverlayService.setHiddenForCapture(false)
                    }
                    isSaving.set(false)
                }
            }, OVERLAY_HIDE_MS)
        }
    }

    private fun grabFrameAfterOverlayHidden(forceKeep: Boolean) {
        if (!isCapturing.get()) return
        val reader = imageReader ?: return
        var image: Image? = null
        try {
            image = acquireImageAfterOverlayHide(reader)
            if (image == null) {
                CaptureEventBus.emit(
                    mapOf(
                        "type" to "error",
                        "message" to "Не удалось получить кадр экрана",
                    ),
                )
                return
            }
            val plane = image.planes[0]
            val buffer = plane.buffer
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * width
            val bitmap = Bitmap.createBitmap(
                width + rowPadding / pixelStride,
                height,
                Bitmap.Config.ARGB_8888,
            )
            bitmap.copyPixelsFromBuffer(buffer)
            val cropped = Bitmap.createBitmap(bitmap, 0, 0, width, height)
            bitmap.recycle()

            if (!forceKeep && !similarityGate.shouldKeep(cropped)) {
                cropped.recycle()
                CaptureEventBus.emit(
                    mapOf(
                        "type" to "skipped",
                        "skipped" to similarityGate.skippedCount(),
                        "count" to collectedPaths.size,
                    ),
                )
                return
            }
            if (forceKeep) {
                similarityGate.remember(cropped)
            }

            val fgPackage = lastKnownForegroundPackage
                ?: ForegroundAppHelper.currentForegroundPackage(this)
            if (!fgPackage.isNullOrBlank()) {
                lastKnownForegroundPackage = fgPackage
            }
            val fgLabel = fgPackage?.let { ForegroundAppHelper.labelForPackage(this, it) }

            val dir = File(cacheDir, "captures/$sessionId").apply { mkdirs() }
            val file = File(dir, "shot_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { out ->
                cropped.compress(Bitmap.CompressFormat.JPEG, 72, out)
            }
            cropped.recycle()

            collectedPaths.add(file.absolutePath)
            val count = collectedPaths.size
            refreshChrome(count)
            CaptureEventBus.emit(
                mapOf(
                    "type" to "screenshot",
                    "path" to file.absolutePath,
                    "count" to count,
                    "skipped" to similarityGate.skippedCount(),
                    "manual" to forceKeep,
                    "foregroundPackage" to fgPackage,
                    "foregroundLabel" to fgLabel,
                ),
            )
        } catch (e: Exception) {
            CaptureEventBus.emit(
                mapOf("type" to "error", "message" to (e.message ?: "Capture failed")),
            )
        } finally {
            image?.close()
        }
    }

    /**
     * VirtualDisplay often does not push a new ImageReader frame on a static
     * screen. Never discard the only buffer and return empty — keep polling for
     * a newer frame, then fall back to the latest available image.
     */
    private fun acquireImageAfterOverlayHide(reader: ImageReader): Image? {
        val deadline = SystemClock.elapsedRealtime() + FRAME_POLL_MS
        var latest: Image? = null
        while (SystemClock.elapsedRealtime() < deadline) {
            val next = try {
                reader.acquireLatestImage()
            } catch (_: Exception) {
                null
            }
            if (next != null) {
                latest?.close()
                latest = next
                // Keep scanning briefly for a frame composed after overlay detach.
                SystemClock.sleep(32L)
            } else {
                SystemClock.sleep(16L)
            }
        }
        if (latest != null) return latest
        return try {
            reader.acquireLatestImage()
        } catch (_: Exception) {
            null
        }
    }

    private fun finalizeCapture(stopReason: String = "user") {
        if (!isCapturing.getAndSet(false) && mediaProjection == null) {
            return
        }
        isPaused.set(false)
        cancelSessionClock()
        captureRunnable?.let { handler?.removeCallbacks(it) }
        captureRunnable = null

        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }
        virtualDisplay = null

        try {
            imageReader?.close()
        } catch (_: Exception) {
        }
        imageReader = null

        try {
            mediaProjection?.stop()
        } catch (_: Exception) {
        }
        mediaProjection = null

        CaptureOverlayService.setHiddenForCapture(false)
        CaptureOverlayService.hide(this)
        val fgPackage = lastKnownForegroundPackage
        val fgLabel = fgPackage?.let { ForegroundAppHelper.labelForPackage(this, it) }
        CaptureEventBus.emit(
            mapOf(
                "type" to "stopped",
                "paths" to collectedPaths.toList(),
                "reason" to stopReason,
                "targetPackage" to targetPackage,
                "targetLabel" to targetLabel,
                "foregroundPackage" to fgPackage,
                "foregroundLabel" to fgLabel,
            ),
        )

        // Return to UI Clone after stop from overlay / notification / timer
        // so the user sees progress and the result screen.
        bringAppToForeground()

        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    private fun bringAppToForeground() {
        val launch = {
            try {
                val intent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                startActivity(intent)
            } catch (_: Exception) {
            }
        }
        // finalizeCapture may run on the capture HandlerThread; startActivity
        // must be posted to the main looper.
        if (Looper.myLooper() == Looper.getMainLooper()) {
            launch()
        } else {
            Handler(Looper.getMainLooper()).post(launch)
        }
    }

    private fun resolveDisplayMetrics() {
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = wm.currentWindowMetrics.bounds
            width = bounds.width()
            height = bounds.height()
            density = resources.displayMetrics.densityDpi
        } else {
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getRealMetrics(metrics)
            width = metrics.widthPixels
            height = metrics.heightPixels
            density = metrics.densityDpi
        }
        // Cap resolution to keep JPEG payloads reasonable for vision APIs.
        val maxSide = 1280
        if (width > maxSide || height > maxSide) {
            val scale = maxSide.toFloat() / maxOf(width, height)
            width = (width * scale).toInt().coerceAtLeast(720)
            height = (height * scale).toInt().coerceAtLeast(720)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "UI Clone захват",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Запись экрана для анализа UI"
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    private fun buildNotification(count: Int): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopIntent = Intent(this, ScreenCaptureService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val paused = isPaused.get()
        val ownFg = AppForegroundTracker.isOwnAppForeground
        val target = targetPackage
        val fgPkg = lastKnownForegroundPackage
        val waitingTarget = !target.isNullOrBlank() &&
            !ownFg &&
            (
                !ForegroundAppHelper.canTrackForeground(this) ||
                    fgPkg != target
                )
        val remainingSec = remainingSecNow()
        val nearLimit = remainingSec <= (warnBeforeMs / 1000L).toInt()
        val label = targetLabel?.let { " · $it" } ?: ""
        val skipped = similarityGate.skippedCount()
        val skippedPart = if (skipped > 0) " · дублей пропущено: $skipped" else ""
        val timePart = " · осталось ${formatRemaining(remainingSec)}"
        val openNow = when {
            !waitingTarget -> ""
            fgPkg.isNullOrBlank() -> " · не цель (home/другое)"
            else -> " · сейчас: ${ForegroundAppHelper.labelForPackage(this, fgPkg)}"
        }
        val statusTitle = when {
            ownFg -> "UI Clone: ждём целевое app$label"
            waitingTarget -> "UI Clone: не та цель$label"
            paused -> "UI Clone: пауза$label"
            nearLimit -> "UI Clone: скоро стоп$label"
            else -> "UI Clone: идёт сбор$label"
        }
        val modeHint = when {
            ownFg -> " · откройте цель"
            waitingTarget -> openNow
            paused -> " · «Далее» или Стоп"
            captureMode == "manual" -> " · «+ кадр» или Стоп"
            captureMode == "both" -> " · таймер + «+ кадр»"
            else -> " · «Стоп»"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(statusTitle)
            .setContentText("Скриншотов: $count$skippedPart$timePart$modeHint")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openPending)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        if (allowsManual) {
            val shotIntent = Intent(this, ScreenCaptureService::class.java).apply {
                action = ACTION_SHOT
            }
            val shotPending = PendingIntent.getService(
                this,
                2,
                shotIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.addAction(0, "+ кадр", shotPending)
        }

        val pauseIntent = Intent(this, ScreenCaptureService::class.java).apply {
            action = ACTION_TOGGLE_PAUSE
        }
        val pausePending = PendingIntent.getService(
            this,
            3,
            pauseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        builder.addAction(0, if (paused) "Далее" else "Пауза", pausePending)
        builder.addAction(0, "Стоп", stopPending)
        return builder.build()
    }

    private fun formatRemaining(totalSec: Int): String {
        val m = totalSec / 60
        val s = totalSec % 60
        return "%d:%02d".format(m, s)
    }

    private fun updateNotification(count: Int) {
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, buildNotification(count))
    }

    override fun onDestroy() {
        finalizeCapture()
        handlerThread?.quitSafely()
        handlerThread = null
        handler = null
        instance = null
        super.onDestroy()
    }
}
