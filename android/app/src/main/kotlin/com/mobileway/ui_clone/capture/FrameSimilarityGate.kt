package com.mobileway.ui_clone.capture

import android.graphics.Bitmap
import kotlin.math.abs

/**
 * Cheap perceptual fingerprint for near-duplicate screenshot detection.
 * Downscales to [SIZE]×[SIZE] grayscale and compares mean absolute difference.
 */
class FrameSimilarityGate(
    private val maxDiffPercent: Float = DEFAULT_MAX_DIFF_PERCENT,
) {
    companion object {
        const val SIZE = 16
        /** Frames with MAD below this % of 255 are treated as duplicates. */
        const val DEFAULT_MAX_DIFF_PERCENT = 2.5f
    }

    private var lastFingerprint: IntArray? = null
    private var skippedCount: Int = 0

    fun skippedCount(): Int = skippedCount

    fun reset() {
        lastFingerprint = null
        skippedCount = 0
    }

    /**
     * @return true if [bitmap] is different enough to keep; false if duplicate.
     */
    fun shouldKeep(bitmap: Bitmap): Boolean {
        val fingerprint = fingerprint(bitmap)
        val previous = lastFingerprint
        if (previous != null) {
            val diffPercent = meanAbsDiffPercent(previous, fingerprint)
            if (diffPercent < maxDiffPercent) {
                skippedCount++
                return false
            }
        }
        lastFingerprint = fingerprint
        return true
    }

    /** Update baseline without counting a skip (e.g. after a forced manual shot). */
    fun remember(bitmap: Bitmap) {
        lastFingerprint = fingerprint(bitmap)
    }

    private fun fingerprint(source: Bitmap): IntArray {
        val scaled = Bitmap.createScaledBitmap(source, SIZE, SIZE, true)
        val pixels = IntArray(SIZE * SIZE)
        scaled.getPixels(pixels, 0, SIZE, 0, 0, SIZE, SIZE)
        if (scaled !== source) {
            scaled.recycle()
        }
        val out = IntArray(SIZE * SIZE)
        for (i in pixels.indices) {
            val c = pixels[i]
            val r = (c shr 16) and 0xFF
            val g = (c shr 8) and 0xFF
            val b = c and 0xFF
            // Rec. 601 luma
            out[i] = (r * 299 + g * 587 + b * 114) / 1000
        }
        return out
    }

    private fun meanAbsDiffPercent(a: IntArray, b: IntArray): Float {
        var sum = 0L
        for (i in a.indices) {
            sum += abs(a[i] - b[i])
        }
        val mean = sum.toFloat() / a.size
        return mean * 100f / 255f
    }
}
