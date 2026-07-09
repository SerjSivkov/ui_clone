package com.mobileway.ui_clone.capture

object CaptureEventBus {
    @Volatile
    var listener: ((Map<String, Any?>) -> Unit)? = null

    fun emit(event: Map<String, Any?>) {
        listener?.invoke(event)
    }
}
