package kr.comong.daoapp.grip

import android.graphics.Bitmap
import androidx.camera.core.ImageProxy
import java.nio.ByteBuffer

fun ImageProxy.toRgbaBitmap(): Bitmap? {
    return try {
        val plane = planes[0]
        val buffer = plane.buffer
        buffer.rewind()
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)

        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bmp.copyPixelsFromBuffer(ByteBuffer.wrap(bytes))
        bmp
    } catch (_: Exception) {
        null
    }
}