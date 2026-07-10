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
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_RESULT_DATA = "resultData"
        const val EXTRA_SESSION_ID = "sessionId"
        const val EXTRA_TARGET_PACKAGE = "targetPackage"
        const val EXTRA_TARGET_LABEL = "targetLabel"
        const val EXTRA_INTERVAL_MS = "intervalMs"
        const val EXTRA_SIMILARITY_PERCENT = "similarityPercent"
        /** timer | manual | both */
        const val EXTRA_CAPTURE_MODE = "captureMode"

        private const val CHANNEL_ID = "ui_clone_capture"
        private const val NOTIFICATION_ID = 7101
        private const val MAX_SHOTS = 40

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

    private var sessionId: String = ""
    private var targetLabel: String? = null
    private var intervalMs: Long = 1500L
    /** timer | manual | both */
    private var captureMode: String = "timer"
    private var width = 0
    private var height = 0
    private var density = 0

    private val isCapturing = AtomicBoolean(false)
    private val isSaving = AtomicBoolean(false)
    private var similarityGate = FrameSimilarityGate()

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
                    // Manual shots bypass similarity gate so the user always
                    // gets the frame they asked for.
                    handler?.post { captureFrame(forceKeep = true) }
                }
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
        targetLabel = intent.getStringExtra(EXTRA_TARGET_LABEL)
        intervalMs = intent.getLongExtra(EXTRA_INTERVAL_MS, 1500L).coerceIn(800L, 5000L)
        captureMode = when (intent.getStringExtra(EXTRA_CAPTURE_MODE)) {
            "manual" -> "manual"
            "both" -> "both"
            else -> "timer"
        }
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

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
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
        CaptureOverlayService.show(this, 0, showShotButton = allowsManual)
        CaptureEventBus.emit(
            mapOf(
                "type" to "started",
                "sessionId" to sessionId,
                "targetLabel" to targetLabel,
                "captureMode" to captureMode,
            ),
        )

        if (allowsTimer) {
            val runnable = object : Runnable {
                override fun run() {
                    if (!isCapturing.get()) return
                    captureFrame(forceKeep = false)
                    handler?.postDelayed(this, intervalMs)
                }
            }
            captureRunnable = runnable
            handler?.postDelayed(runnable, 600L)
        }
    }

    private fun captureFrame(forceKeep: Boolean = false) {
        if (!isCapturing.get() || isSaving.get()) return
        if (collectedPaths.size >= MAX_SHOTS) {
            finalizeCapture()
            stopSelf()
            return
        }

        val reader = imageReader ?: return
        var image: Image? = null
        try {
            image = reader.acquireLatestImage() ?: return
            isSaving.set(true)
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

            val dir = File(cacheDir, "captures/$sessionId").apply { mkdirs() }
            val file = File(dir, "shot_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { out ->
                cropped.compress(Bitmap.CompressFormat.JPEG, 72, out)
            }
            cropped.recycle()

            collectedPaths.add(file.absolutePath)
            val count = collectedPaths.size
            updateNotification(count)
            CaptureOverlayService.updateCount(this, count, showShotButton = allowsManual)
            CaptureEventBus.emit(
                mapOf(
                    "type" to "screenshot",
                    "path" to file.absolutePath,
                    "count" to count,
                    "skipped" to similarityGate.skippedCount(),
                    "manual" to forceKeep,
                ),
            )
        } catch (e: Exception) {
            CaptureEventBus.emit(
                mapOf("type" to "error", "message" to (e.message ?: "Capture failed")),
            )
        } finally {
            image?.close()
            isSaving.set(false)
        }
    }

    private fun finalizeCapture() {
        if (!isCapturing.getAndSet(false) && mediaProjection == null) {
            return
        }
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

        CaptureOverlayService.hide(this)
        CaptureEventBus.emit(
            mapOf(
                "type" to "stopped",
                "paths" to collectedPaths.toList(),
            ),
        )

        stopForeground(STOP_FOREGROUND_REMOVE)
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

        val label = targetLabel?.let { " · $it" } ?: ""
        val skipped = similarityGate.skippedCount()
        val skippedPart = if (skipped > 0) " · дублей пропущено: $skipped" else ""
        val modeHint = when (captureMode) {
            "manual" -> " · «+ кадр» или Стоп"
            "both" -> " · таймер + «+ кадр»"
            else -> " · «Стоп»"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("UI Clone: идёт сбор$label")
            .setContentText("Скриншотов: $count$skippedPart$modeHint")
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
        builder.addAction(0, "Стоп", stopPending)
        return builder.build()
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
