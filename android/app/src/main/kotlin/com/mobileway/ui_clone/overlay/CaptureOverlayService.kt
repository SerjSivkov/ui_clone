package com.mobileway.ui_clone.overlay

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import com.mobileway.ui_clone.R
import com.mobileway.ui_clone.capture.ScreenCaptureService
import kotlin.math.abs

class CaptureOverlayService : Service() {
    companion object {
        const val ACTION_SHOW = "com.mobileway.ui_clone.overlay.SHOW"
        const val ACTION_HIDE = "com.mobileway.ui_clone.overlay.HIDE"
        const val EXTRA_COUNT = "count"
        const val EXTRA_SHOW_SHOT = "showShot"
        const val EXTRA_PAUSED = "paused"

        private const val PREFS = "overlay_controls"
        private const val KEY_X = "x"
        private const val KEY_Y = "y"
        private const val KEY_HAS_POS = "has_pos"

        fun show(
            context: Context,
            count: Int = 0,
            showShotButton: Boolean = false,
            paused: Boolean = false,
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                !Settings.canDrawOverlays(context)
            ) {
                return
            }
            val intent = Intent(context, CaptureOverlayService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_COUNT, count)
                putExtra(EXTRA_SHOW_SHOT, showShotButton)
                putExtra(EXTRA_PAUSED, paused)
            }
            context.startService(intent)
        }

        fun hide(context: Context) {
            val intent = Intent(context, CaptureOverlayService::class.java).apply {
                action = ACTION_HIDE
            }
            context.startService(intent)
        }

        fun update(
            context: Context,
            count: Int,
            showShotButton: Boolean = false,
            paused: Boolean = false,
        ) {
            show(context, count, showShotButton = showShotButton, paused = paused)
        }

        /** Hide overlay while MediaProjection grabs a frame (avoids panel in shots). */
        fun setHiddenForCapture(hidden: Boolean) {
            val svc = instance ?: return
            if (Looper.myLooper() == Looper.getMainLooper()) {
                svc.applyHiddenForCapture(hidden)
            } else {
                Handler(Looper.getMainLooper()).post {
                    instance?.applyHiddenForCapture(hidden)
                }
            }
        }

        @Volatile
        private var instance: CaptureOverlayService? = null
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var countView: TextView? = null
    private var shotButton: ImageView? = null
    private var pauseButton: ImageView? = null
    private var hiddenForCapture = false
    private var baseLayoutFlags = 0
    private var attachedToWm = false

    private val prefs: SharedPreferences
        get() = getSharedPreferences(PREFS, MODE_PRIVATE)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    private fun applyHiddenForCapture(hidden: Boolean) {
        hiddenForCapture = hidden
        val view = overlayView ?: return
        val params = layoutParams ?: return
        val wm = windowManager ?: return
        if (hidden) {
            // Detach from WindowManager so MediaProjection recomposes without the panel.
            // Alpha-only leave a stale ImageReader buffer and often no new frame on a
            // static screen — acquireLatestImage() then returns null.
            if (attachedToWm) {
                try {
                    wm.removeView(view)
                } catch (_: Exception) {
                }
                attachedToWm = false
            }
        } else {
            view.alpha = 1f
            view.visibility = View.VISIBLE
            params.flags = baseLayoutFlags
            if (!attachedToWm) {
                try {
                    wm.addView(view, params)
                    attachedToWm = true
                } catch (_: Exception) {
                }
            } else {
                try {
                    wm.updateViewLayout(view, params)
                } catch (_: Exception) {
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_HIDE -> {
                removeOverlay()
                stopSelf()
            }
            ACTION_SHOW, null -> {
                val count = intent?.getIntExtra(EXTRA_COUNT, 0) ?: 0
                val showShot = intent?.getBooleanExtra(EXTRA_SHOW_SHOT, false) ?: false
                val paused = intent?.getBooleanExtra(EXTRA_PAUSED, false) ?: false
                ensureOverlay()
                countView?.text = count.toString()
                shotButton?.visibility = if (showShot) View.VISIBLE else View.GONE
                pauseButton?.let { btn ->
                    if (paused) {
                        btn.setImageResource(R.drawable.ic_overlay_play)
                        btn.contentDescription = getString(R.string.overlay_resume)
                    } else {
                        btn.setImageResource(R.drawable.ic_overlay_pause)
                        btn.contentDescription = getString(R.string.overlay_pause)
                    }
                }
                // refreshChrome may run while a frame grab has the panel hidden —
                // keep alpha / NOT_TOUCHABLE in sync.
                if (hiddenForCapture) {
                    applyHiddenForCapture(true)
                }
            }
        }
        return START_STICKY
    }

    private fun ensureOverlay() {
        if (overlayView != null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(this)
        ) {
            stopSelf()
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.overlay_capture_controls, null)
        countView = view.findViewById(R.id.overlay_count)
        shotButton = view.findViewById(R.id.overlay_shot)
        pauseButton = view.findViewById(R.id.overlay_pause)
        val stopButton = view.findViewById<ImageView>(R.id.overlay_stop)
        val dragHandle = view.findViewById<View>(R.id.overlay_drag)

        shotButton?.setOnClickListener {
            ScreenCaptureService.requestShot(this)
        }
        pauseButton?.setOnClickListener {
            ScreenCaptureService.requestTogglePause(this)
        }
        stopButton.setOnClickListener {
            ScreenCaptureService.requestStop(this)
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            val saved = prefs
            if (saved.getBoolean(KEY_HAS_POS, false)) {
                x = saved.getInt(KEY_X, 24)
                y = saved.getInt(KEY_Y, 180)
            } else {
                val metrics = resources.displayMetrics
                // Default: top-right-ish until first layout measures width.
                x = (metrics.widthPixels * 0.55f).toInt()
                y = (180 * metrics.density).toInt()
            }
        }
        baseLayoutFlags = params.flags

        attachDrag(dragHandle, view, params)
        // Also allow dragging from the counter label.
        attachDrag(countView!!, view, params)

        windowManager?.addView(view, params)
        overlayView = view
        layoutParams = params
        attachedToWm = true
        if (hiddenForCapture) {
            applyHiddenForCapture(true)
        }
    }

    private fun attachDrag(
        handle: View,
        panel: View,
        params: WindowManager.LayoutParams,
    ) {
        val touchSlop = ViewConfiguration.get(this).scaledTouchSlop
        var startRawX = 0f
        var startRawY = 0f
        var startParamX = 0
        var startParamY = 0
        var dragging = false

        handle.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startRawX = event.rawX
                    startRawY = event.rawY
                    startParamX = params.x
                    startParamY = params.y
                    dragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - startRawX).toInt()
                    val dy = (event.rawY - startRawY).toInt()
                    if (!dragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        dragging = true
                    }
                    if (dragging) {
                        val metrics = resources.displayMetrics
                        val maxX = (metrics.widthPixels - panel.width).coerceAtLeast(0)
                        val maxY = (metrics.heightPixels - panel.height).coerceAtLeast(0)
                        params.x = (startParamX + dx).coerceIn(0, maxX)
                        params.y = (startParamY + dy).coerceIn(0, maxY)
                        windowManager?.updateViewLayout(panel, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragging) {
                        prefs.edit()
                            .putBoolean(KEY_HAS_POS, true)
                            .putInt(KEY_X, params.x)
                            .putInt(KEY_Y, params.y)
                            .apply()
                    }
                    dragging
                }
                else -> false
            }
        }
    }

    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {
            }
        }
        overlayView = null
        layoutParams = null
        countView = null
        shotButton = null
        pauseButton = null
        attachedToWm = false
        hiddenForCapture = false
    }

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        removeOverlay()
        super.onDestroy()
    }
}
