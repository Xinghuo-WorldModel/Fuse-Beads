package com.pindou.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pindou.app/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToGallery") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val filename = call.argument<String>("filename")
                    if (bytes != null && filename != null) {
                        val path = saveImageToGallery(bytes, filename)
                        if (path != null) {
                            result.success("已保存到相册")
                        } else {
                            result.error("SAVE_FAILED", "保存失败", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "参数无效", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveImageToGallery(bytes: ByteArray, filename: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ use MediaStore
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(
                        MediaStore.Images.Media.RELATIVE_PATH,
                        "${Environment.DIRECTORY_PICTURES}/酥豆"
                    )
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val resolver = contentResolver
                val uri = resolver.insert(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    contentValues
                ) ?: return null

                resolver.openOutputStream(uri)?.use { os ->
                    os.write(bytes)
                }

                contentValues.clear()
                contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)

                uri.toString()
            } else {
                // Android 9 and below
                val dir = Environment.getExternalStoragePublicDirectory(
                    "${Environment.DIRECTORY_PICTURES}/酥豆"
                )
                if (!dir.exists()) dir.mkdirs()

                val file = java.io.File(dir, filename)
                file.writeBytes(bytes)

                // Notify media scanner
                val uri = android.net.Uri.fromFile(file)
                sendBroadcast(
                    android.content.Intent(
                        android.content.Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri
                    )
                )

                file.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
