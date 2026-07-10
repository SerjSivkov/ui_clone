package com.mobileway.ui_clone.capture

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager

/**
 * Tracks the foreground app package via window-state accessibility events.
 * More reliable than UsageStats for "is target still on screen?" filtering.
 */
class ForegroundAccessibilityService : AccessibilityService() {
    companion object {
        @Volatile
        var foregroundPackage: String? = null
            private set

        @Volatile
        private var connected = false

        fun isConnected(): Boolean = connected

        fun isEnabled(context: Context): Boolean {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
                ?: return false
            if (!am.isEnabled) return false
            val expected = ComponentName(context, ForegroundAccessibilityService::class.java)
            val expectedId = expected.flattenToString()
            val enabled = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ) ?: return false
            return enabled.split(':').any { entry ->
                val cn = ComponentName.unflattenFromString(entry)
                cn != null && (
                    cn.flattenToString().equals(expectedId, ignoreCase = true) ||
                        (cn.packageName == expected.packageName && cn.className == expected.className)
                    )
            }
        }

        fun openSettings(context: Context) {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }

        private fun isTransientPackage(packageName: String): Boolean {
            val p = packageName.lowercase()
            return p.contains("inputmethod") ||
                p.contains("keyboard") ||
                p == "com.android.systemui" ||
                p.endsWith(".permissioncontroller") ||
                p.contains("screenshot")
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        connected = true
        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOWS_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        rootInActiveWindow?.packageName?.toString()?.let { pkg ->
            if (!isTransientPackage(pkg)) {
                foregroundPackage = pkg
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val type = event.eventType
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            type != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) {
            return
        }
        val fromEvent = event.packageName?.toString()
        val fromRoot = rootInActiveWindow?.packageName?.toString()
        val pkg = when {
            !fromRoot.isNullOrBlank() && !isTransientPackage(fromRoot) -> fromRoot
            !fromEvent.isNullOrBlank() && !isTransientPackage(fromEvent) -> fromEvent
            else -> null
        } ?: return
        foregroundPackage = pkg
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        connected = false
        super.onDestroy()
    }
}
