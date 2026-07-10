package com.mobileway.ui_clone.capture

/**
 * Tracks whether [com.mobileway.ui_clone.MainActivity] is visible.
 * Used to skip MediaProjection frames of our own UI.
 */
object AppForegroundTracker {
    @Volatile
    var isOwnAppForeground: Boolean = false
        private set

    fun setOwnAppForeground(value: Boolean) {
        isOwnAppForeground = value
    }
}
