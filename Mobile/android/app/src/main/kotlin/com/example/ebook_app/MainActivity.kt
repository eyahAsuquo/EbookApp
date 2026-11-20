package com.example.ebook_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.ebook_app/file_channel"
    private var pendingFilePath: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        pendingFilePath?.let { path ->
            methodChannel?.invokeMethod("onPdfOpened", path)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialPdf" -> {
                        val path = pendingFilePath
                        pendingFilePath = null
                        result.success(path)
                    }
                    "openDefaultAppSettings" -> {
                        val opened = openDefaultAppSettings()
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val data: Uri? = intent.data

        if (Intent.ACTION_VIEW == action && data != null) {
            val resolvedPath = resolveUriToFilePath(data)
            if (resolvedPath != null) {
                pendingFilePath = resolvedPath
            }
        }
    }

    private fun resolveUriToFilePath(uri: Uri): String? {
        return try {
            if ("file".equals(uri.scheme, ignoreCase = true)) {
                uri.path
            } else if ("content".equals(uri.scheme, ignoreCase = true)) {
                var fileName = "document.pdf"
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        val displayName = cursor.getString(nameIndex)
                        if (!displayName.isNullOrBlank()) {
                            fileName = displayName
                        }
                    }
                }
                if (!fileName.endsWith(".pdf", ignoreCase = true)) {
                    fileName = "$fileName.pdf"
                }

                val tempFile = File(cacheDir, fileName)
                contentResolver.openInputStream(uri)?.use { inputStream ->
                    FileOutputStream(tempFile).use { outputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
                tempFile.absolutePath
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun openDefaultAppSettings(): Boolean {
        return try {
            val intent = Intent(android.provider.Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", packageName, null)
                }
                startActivity(intent)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
