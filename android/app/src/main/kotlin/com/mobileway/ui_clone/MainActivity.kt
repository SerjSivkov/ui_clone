package com.mobileway.ui_clone

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.mobileway.ui_clone.capture.AppListHelper
import com.mobileway.ui_clone.capture.CaptureEventBus
import com.mobileway.ui_clone.capture.ScreenCaptureService

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.mobileway.ui_clone/capture"
        private const val EVENT_CHANNEL = "com.mobileway.ui_clone/capture_events"
        private const val REQ_MEDIA_PROJECTION = 4401
        private const val REQ_OVERLAY = 4402
        private const val REQ_NOTIFICATIONS = 4403
    }

    private var pendingStartArgs: Map<String, Any?>? = null
    private var methodResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        CaptureEventBus.listener = { event ->
            runOnUiThread { eventSink?.success(event) }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                "listInstalledApps" -> {
                    try {
                        result.success(AppListHelper.listLaunchableApps(this))
                    } catch (e: Exception) {
                        result.error("APP_LIST", e.message, null)
                    }
                }
                "hasOverlayPermission" -> {
                    result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                            Settings.canDrawOverlays(this),
                    )
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !Settings.canDrawOverlays(this)
                    ) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        )
                        startActivityForResult(intent, REQ_OVERLAY)
                    }
                    result.success(null)
                }
                "startCapture" -> {
                    ensureNotificationPermission()
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                    pendingStartArgs = args.entries.associate { it.key.toString() to it.value }
                    methodResult = result
                    val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    startActivityForResult(
                        mpm.createScreenCaptureIntent(),
                        REQ_MEDIA_PROJECTION,
                    )
                }
                "stopCapture" -> {
                    val paths = ScreenCaptureService.stopAndCollect(this)
                    result.success(paths)
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("ARGS", "packageName required", null)
                        return@setMethodCallHandler
                    }
                    val launch = packageManager.getLaunchIntentForPackage(packageName)
                    if (launch == null) {
                        result.error("NOT_FOUND", "Cannot launch $packageName", null)
                        return@setMethodCallHandler
                    }
                    launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(launch)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_MEDIA_PROJECTION) return

        val result = methodResult
        methodResult = null
        val args = pendingStartArgs
        pendingStartArgs = null

        if (resultCode != Activity.RESULT_OK || data == null || args == null) {
            result?.error("PERMISSION_DENIED", "Screen capture permission denied", null)
            return
        }

        val serviceIntent = Intent(this, ScreenCaptureService::class.java).apply {
            action = ScreenCaptureService.ACTION_START
            putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ScreenCaptureService.EXTRA_RESULT_DATA, data)
            putExtra(
                ScreenCaptureService.EXTRA_SESSION_ID,
                args["sessionId"] as? String ?: "",
            )
            putExtra(
                ScreenCaptureService.EXTRA_TARGET_PACKAGE,
                args["targetPackage"] as? String,
            )
            putExtra(
                ScreenCaptureService.EXTRA_TARGET_LABEL,
                args["targetLabel"] as? String,
            )
            putExtra(
                ScreenCaptureService.EXTRA_INTERVAL_MS,
                (args["intervalMs"] as? Number)?.toLong() ?: 1500L,
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        result?.success(null)
    }

    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQ_NOTIFICATIONS,
            )
        }
    }

    override fun onDestroy() {
        CaptureEventBus.listener = null
        super.onDestroy()
    }
}
