package com.reactnativemultipleimagepicker

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.BitmapFactory
import java.io.File

object ImageLoaderUtils {
    fun assertValidRequest(context: Context?): Boolean {
        if (context is Activity) {
            return !isDestroy(context)
        } else if (context is ContextWrapper) {
            if (context.baseContext is Activity) {
                val activity = context.baseContext as Activity
                return !isDestroy(activity)
            }
        }
        return true
    }

    private fun isDestroy(activity: Activity?): Boolean {
        return if (activity == null) {
            true
        } else activity.isFinishing || activity.isDestroyed
    }

  fun getImageDimensionsAndSize(filePath: String): Triple<Int, Int, Double>? {
    val file = File(filePath)
    if (!file.exists()) return null

    val options = BitmapFactory.Options().apply {
      inJustDecodeBounds = true
    }

    BitmapFactory.decodeFile(filePath, options)

    val width = options.outWidth
    val height = options.outHeight
    val size = file.length()

    if (width != -1 && height != -1) {
      return Triple(width, height, size.toDouble())
    }

    return null
  }
}
