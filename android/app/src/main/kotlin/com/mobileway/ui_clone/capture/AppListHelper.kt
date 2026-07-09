package com.mobileway.ui_clone.capture

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Base64
import java.io.ByteArrayOutputStream

object AppListHelper {
    fun listLaunchableApps(context: Context): List<Map<String, Any?>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }

        val self = context.packageName
        return resolveInfos
            .asSequence()
            .mapNotNull { info ->
                val appInfo = info.activityInfo?.applicationInfo ?: return@mapNotNull null
                val packageName = appInfo.packageName
                if (packageName == self) return@mapNotNull null
                val label = info.loadLabel(pm)?.toString() ?: packageName
                val isSystem =
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val iconBase64 = try {
                    drawableToBase64(info.loadIcon(pm))
                } catch (_: Exception) {
                    null
                }
                mapOf(
                    "packageName" to packageName,
                    "label" to label,
                    "iconBase64" to iconBase64,
                    "isSystemApp" to isSystem,
                )
            }
            .distinctBy { it["packageName"] }
            .sortedBy { (it["label"] as String).lowercase() }
            .toList()
    }

    private fun drawableToBase64(drawable: Drawable): String? {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            else -> {
                val width = (drawable.intrinsicWidth.takeIf { it > 0 } ?: 96)
                val height = (drawable.intrinsicHeight.takeIf { it > 0 } ?: 96)
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
        }
        val scaled = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.PNG, 90, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }
}
