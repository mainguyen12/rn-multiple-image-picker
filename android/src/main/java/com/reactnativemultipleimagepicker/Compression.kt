package com.reactnativemultipleimagepicker

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.os.Environment
import android.util.Log
import android.util.Pair
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import java.io.*
import java.util.*


/**
 * Created by ipusic on 12/27/16.
 */
object Compression {
  @Throws(IOException::class)
  fun resize(
    originalImagePath: String,
    originalWidth: Int,
    originalHeight: Int,
    maxWidth: Int,
    maxHeight: Int,
    quality: Int
  ): String {
    if (originalImagePath?.length == 0) return originalImagePath
    val targetDimensions = calculateTargetDimensions(originalWidth, originalHeight, maxWidth, maxHeight)
    val targetWidth = targetDimensions.first
    val targetHeight = targetDimensions.second
    var bitmap: Bitmap? = null
    if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
      bitmap = BitmapFactory.decodeFile(originalImagePath)
    } else {
      val options = BitmapFactory.Options()
      options.inSampleSize = calculateInSampleSize(originalWidth, originalHeight, targetWidth, targetHeight)
      bitmap = BitmapFactory.decodeFile(originalImagePath, options)
    }

    // Use original image exif orientation data to preserve image orientation for the resized bitmap
    val originalExif = ExifInterface(originalImagePath)
    val originalOrientation = originalExif.getAttribute(ExifInterface.TAG_ORIENTATION)
    bitmap = Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    val resizeImageFile = File(originalImagePath)
    val os: OutputStream = BufferedOutputStream(FileOutputStream(resizeImageFile))
    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, os)

    // Don't set unnecessary exif attribute
    if (shouldSetOrientation(originalOrientation)) {
      val exif = ExifInterface(resizeImageFile.absolutePath)
      exif.setAttribute(ExifInterface.TAG_ORIENTATION, originalOrientation)
      exif.saveAttributes()
    }
    os.close()
    bitmap.recycle()
    return originalImagePath
  }

  private fun calculateInSampleSize(originalWidth: Int, originalHeight: Int, requestedWidth: Int, requestedHeight: Int): Int {
    var inSampleSize = 1
    if (originalWidth > requestedWidth || originalHeight > requestedHeight) {
      val halfWidth = originalWidth / 2
      val halfHeight = originalHeight / 2

      // Calculate the largest inSampleSize value that is a power of 2 and keeps both
      // height and width larger than the requested height and width.
      while (halfWidth / inSampleSize >= requestedWidth
        && halfHeight / inSampleSize >= requestedHeight) {
        inSampleSize *= 2
      }
    }
    return inSampleSize
  }

  private fun shouldSetOrientation(orientation: String?): Boolean {
    return (orientation != ExifInterface.ORIENTATION_NORMAL.toString()
      && orientation != ExifInterface.ORIENTATION_UNDEFINED.toString())
  }

  private fun calculateTargetDimensions(currentWidth: Int, currentHeight: Int, maxWidth: Int, maxHeight: Int): Pair<Int, Int> {
    var width = currentWidth
    var height = currentHeight
    if (width > maxWidth) {
      val ratio = maxWidth.toFloat() / width
      height = (height * ratio).toInt()
      width = maxWidth
    }
    if (height > maxHeight) {
      val ratio = maxHeight.toFloat() / height
      width = (width * ratio).toInt()
      height = maxHeight
    }
    return Pair.create(width, height)
  }
}
