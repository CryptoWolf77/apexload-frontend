package com.yahyazlab.apexload

import android.app.Activity
import android.content.Intent
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingTreeResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "apexload/android"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPackageInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(isPackageInstalled(packageName))
                }
                "openStatusTree" -> {
                    val business = call.argument<Boolean>("business") ?: false
                    openStatusTree(result, business)
                }
                "listDocumentTree" -> {
                    val treeUri = call.argument<String>("treeUri")
                    if (treeUri.isNullOrBlank()) {
                        result.success(emptyList<Map<String, Any?>>())
                        return@setMethodCallHandler
                    }
                    result.success(listDocumentTree(treeUri))
                }
                "copyDocumentToCache" -> {
                    val uri = call.argument<String>("uri")
                    val fileName = call.argument<String>("fileName") ?: "status_file"
                    if (uri.isNullOrBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    result.success(copyDocumentToCache(uri, fileName))
                }
                "publishToGallery" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName") ?: "apexload_file"
                    val type = call.argument<String>("type") ?: "video"
                    val category = call.argument<String>("category") ?: ""
                    if (sourcePath.isNullOrBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    result.success(publishToGallery(sourcePath, fileName, type, category))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != STATUS_TREE_REQUEST) return
        val result = pendingTreeResult
        pendingTreeResult = null
        if (result == null) return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        val flags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {
        }
        result.success(uri.toString())
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openStatusTree(result: MethodChannel.Result, business: Boolean) {
        if (pendingTreeResult != null) {
            result.error("picker_active", "A folder picker is already open.", null)
            return
        }
        pendingTreeResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialWhatsAppMediaUri(business))
            }
        }
        startActivityForResult(intent, STATUS_TREE_REQUEST)
    }

    private fun initialWhatsAppMediaUri(business: Boolean): Uri {
        val documentId = if (business) {
            "primary:Android/media/com.whatsapp.w4b/WhatsApp Business/Media"
        } else {
            "primary:Android/media/com.whatsapp/WhatsApp/Media"
        }
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            documentId
        )
    }

    private fun listDocumentTree(treeUriValue: String): List<Map<String, Any?>> {
        return try {
            val treeUri = Uri.parse(treeUriValue)
            val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                treeDocumentId
            )
            val rows = mutableListOf<Map<String, Any?>>()
            rows.addAll(listChildren(treeUri, childrenUri, includeStatusChildren = true))
            rows
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun listChildren(
        treeUri: Uri,
        childrenUri: Uri,
        includeStatusChildren: Boolean
    ): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED
            ),
            null,
            null,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val sizeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
            val modifiedIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
            while (cursor.moveToNext()) {
                val documentId = cursor.getString(idIndex)
                val name = cursor.getString(nameIndex) ?: ""
                val mime = cursor.getString(mimeIndex) ?: ""
                if (
                    includeStatusChildren &&
                    name == ".Statuses" &&
                    mime == DocumentsContract.Document.MIME_TYPE_DIR
                ) {
                    val nested = DocumentsContract.buildChildDocumentsUriUsingTree(
                        treeUri,
                        documentId
                    )
                    rows.addAll(listChildren(treeUri, nested, includeStatusChildren = false))
                    continue
                }
                val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                rows.add(
                    mapOf(
                        "uri" to docUri.toString(),
                        "name" to name,
                        "mimeType" to mime,
                        "size" to if (sizeIndex >= 0) cursor.getLong(sizeIndex) else 0L,
                        "modified" to if (modifiedIndex >= 0) cursor.getLong(modifiedIndex) else 0L
                    )
                )
            }
        }
        return rows
    }

    private fun copyDocumentToCache(uriValue: String, fileName: String): String? {
        return try {
            val uri = Uri.parse(uriValue)
            val safeName = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_")
            val folder = File(cacheDir, "whatsapp_status")
            if (!folder.exists()) folder.mkdirs()
            val target = File(folder, safeName)
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun publishToGallery(
        sourcePath: String,
        fileName: String,
        type: String,
        category: String
    ): String? {
        return try {
            val source = File(sourcePath)
            if (!source.exists() || source.length() <= 0) return null
            val resolver = contentResolver
            val safeName = fileName.replace(Regex("[\\\\/:*?\"<>|]"), "_")
            val mime = mimeTypeFor(safeName, type)
            val relativePath = relativeGalleryPath(type, category)
            val collection = when (type) {
                "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            }
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }
            val uri = resolver.insert(collection, values) ?: return null
            resolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: return null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val done = ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }
                resolver.update(uri, done, null, null)
            }
            uri.toString()
        } catch (_: Exception) {
            null
        }
    }

    private fun relativeGalleryPath(type: String, category: String): String {
        return when {
            category == "status" && type == "image" -> "Pictures/ApexLoad/Statuses"
            category == "status" -> "Movies/ApexLoad/Statuses"
            category == "edited" && type == "video" -> "Movies/ApexLoad/Edited"
            type == "audio" -> "Music/ApexLoad"
            type == "image" -> "Pictures/ApexLoad"
            else -> "Movies/ApexLoad"
        }
    }

    private fun mimeTypeFor(fileName: String, type: String): String {
        val lower = fileName.lowercase()
        if (type == "audio") return if (lower.endsWith(".m4a")) "audio/mp4" else "audio/mpeg"
        if (type == "image") {
            return when {
                lower.endsWith(".png") -> "image/png"
                lower.endsWith(".webp") -> "image/webp"
                lower.endsWith(".gif") -> "image/gif"
                else -> "image/jpeg"
            }
        }
        return "video/mp4"
    }

    companion object {
        private const val STATUS_TREE_REQUEST = 9231
    }
}
