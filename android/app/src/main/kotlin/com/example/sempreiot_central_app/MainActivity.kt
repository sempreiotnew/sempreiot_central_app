package com.example.sempreiot_central_app

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_CHANNEL = "com.sempreiot.central/storage"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInternalStorage" -> {
                        try {
                            val path = Environment.getDataDirectory().absolutePath
                            val stat = StatFs(path)
                            val totalBytes = stat.blockCountLong * stat.blockSizeLong
                            val availableBytes = stat.availableBlocksLong * stat.blockSizeLong
                            result.success(
                                mapOf(
                                    "totalBytes" to totalBytes,
                                    "availableBytes" to availableBytes,
                                )
                            )
                        } catch (e: Exception) {
                            result.error("STORAGE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
