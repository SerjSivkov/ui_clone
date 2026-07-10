package com.mobileway.ui_clone.capture

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings

/**
 * Detects the current foreground app.
 *
 * Prefer AccessibilityService (instant). Fall back to UsageStats.
 * When a target package is selected, callers should fail closed unless
 * [canTrackForeground] is true and [currentForegroundPackage] == target.
 */
object ForegroundAppHelper {
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun hasAccessibilityAccess(context: Context): Boolean =
        ForegroundAccessibilityService.isEnabled(context)

    /** True if we can reliably know which app is in the foreground. */
    fun canTrackForeground(context: Context): Boolean =
        hasAccessibilityAccess(context) || hasUsageAccess(context)

    fun openUsageAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun openAccessibilitySettings(context: Context) {
        ForegroundAccessibilityService.openSettings(context)
    }

    /**
     * Current foreground package, or null if unknown / home / cleared.
     * Accessibility is preferred; UsageStats is a fallback.
     */
    fun currentForegroundPackage(context: Context): String? {
        if (hasAccessibilityAccess(context)) {
            val fromA11y = ForegroundAccessibilityService.foregroundPackage
            if (!fromA11y.isNullOrBlank()) {
                return fromA11y
            }
        }
        if (hasUsageAccess(context)) {
            return foregroundFromUsageStats(context)
        }
        return null
    }

    private fun foregroundFromUsageStats(context: Context): String? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val end = System.currentTimeMillis()
        val begin = end - 60_000L

        // Prefer most-recently-used app from usage stats (works better on
        // some OEMs than walking pause/resume events alone).
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, begin, end)
        val recent = stats
            ?.filter { it.lastTimeUsed >= begin && it.packageName.isNotBlank() }
            ?.maxByOrNull { it.lastTimeUsed }
        val fromStats = recent?.packageName

        val fromEvents = foregroundFromEvents(usm, begin, end)

        // If events say the last-resumed package was paused (home), trust that.
        if (fromEvents == null && fromStats != null) {
            // Stats still point at an app, but events say nothing is resumed —
            // treat as not in a tracked app foreground (home / unknown).
            return null
        }
        return fromEvents ?: fromStats
    }

    private fun foregroundFromEvents(
        usm: UsageStatsManager,
        begin: Long,
        end: Long,
    ): String? {
        val events = usm.queryEvents(begin, end)
        val event = UsageEvents.Event()
        var lastFgPackage: String? = null
        var lastFgTime = 0L
        var lastBgPackage: String? = null
        var lastBgTime = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName
            if (pkg.isNullOrBlank()) continue
            val time = event.timeStamp
            when {
                isMoveToForeground(event.eventType) -> {
                    if (time >= lastFgTime) {
                        lastFgPackage = pkg
                        lastFgTime = time
                    }
                }
                isMoveToBackground(event.eventType) -> {
                    if (time >= lastBgTime) {
                        lastBgPackage = pkg
                        lastBgTime = time
                    }
                }
            }
        }

        val fg = lastFgPackage ?: return null
        if (lastBgPackage == fg && lastBgTime >= lastFgTime) {
            return null
        }
        return fg
    }

    private fun isMoveToForeground(type: Int): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (type == UsageEvents.Event.ACTIVITY_RESUMED) return true
        }
        @Suppress("DEPRECATION")
        return type == UsageEvents.Event.MOVE_TO_FOREGROUND
    }

    private fun isMoveToBackground(type: Int): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (type == UsageEvents.Event.ACTIVITY_PAUSED) return true
        }
        @Suppress("DEPRECATION")
        return type == UsageEvents.Event.MOVE_TO_BACKGROUND
    }

    fun labelForPackage(context: Context, packageName: String): String {
        return try {
            val pm = context.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            packageName
        }
    }
}
