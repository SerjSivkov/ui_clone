package com.mobileway.ui_clone.overlay

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.mobileway.ui_clone.R
import com.mobileway.ui_clone.capture.ScreenCaptureService

class CaptureOverlayService : Service() {
    companion object {
        const val ACTION_SHOW = "com.mobileway.ui_clone.overlay.SHOW"
        const val ACTION_HIDE = "com.mobileway.ui_clone.overlay.HIDE"
        const val EXTRA_COUNT = "count"

        fun show(context: Context, count: Int = 0) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                !Settings.canDrawOverlays(context)
            ) {
                return
            }
            val intent = Intent(context, CaptureOverlayService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_COUNT, count)
            }
            context.startService(intent)
        }

        fun hide(context: Context) {
            val intent = Intent(context, CaptureOverlayService::class.java).apply {
                action = ACTION_HIDE
            }
            context.startService(intent)
        }

        fun updateCount(context: Context, count: Int) {
            show(context, count)
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countView: TextView? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_HIDE -> {
                removeOverlay()
                stopSelf()
            }
            ACTION_SHOW, null -> {
                val count = intent?.getIntExtra(EXTRA_COUNT, 0) ?: 0
                ensureOverlay()
                countView?.text = count.toString()
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
        val stopButton = view.findViewById<View>(R.id.overlay_stop)

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
            gravity = Gravity.TOP or Gravity.END
            x = 24
            y = 180
        }

        var startX = 0
        var startY = 0
        var paramX = 0
        var paramY = 0

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = event.rawX.toInt()
                    startY = event.rawY.toInt()
                    paramX = params.x
                    paramY = params.y
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = startX - event.rawX.toInt()
                    val dy = event.rawY.toInt() - startY
                    params.x = paramX + dx
                    params.y = paramY + dy
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                else -> false
            }
        }

        windowManager?.addView(view, params)
        overlayView = view
    }

    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
            } catch (_: Exception) {
            }
        }
        overlayView = null
        countView = null
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }
}
