package com.ellyapp.medkit.dbkeystorage

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.NonNull
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Прямий, мінімальний враппер над невеликою, наперед відомою кількістю
 * значень (ключ шифрування локальної БД, ключ шифрування вкладень —
 * розрізняються за `account`) через EncryptedSharedPreferences поверх Android
 * Keystore. Окремий, виділений prefs-файл — не той, що використовує
 * flutter_secure_storage — тож жодного перетину зі старими записами.
 *
 * На відміну від iOS-версії тут нема проблеми "кількох варіантів атрибутів"
 * (Keystore-ключ, яким EncryptedSharedPreferences сам шифрує файл,
 * прив'язаний до заліза за конструкцією androidx.security.crypto, без ручного
 * керування accessibility/synchronizable) — але для симетрії і про всяк
 * випадок сховище так само ізольоване в окремому файлі з фіксованим ім'ям,
 * а кожен секрет — під власним, окремим ключем усередині нього.
 */
class MedkitDbKeyStoragePlugin : FlutterPlugin, MethodCallHandler {
  companion object {
    private const val PREFS_FILE_NAME = "medkit_db_key_storage_prefs"
    private const val DEFAULT_ACCOUNT = "db_encryption_key"
  }

  private lateinit var channel: MethodChannel
  private lateinit var appContext: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "medkit.dev/db_key_storage")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun prefs(): SharedPreferences {
    val masterKey = MasterKey.Builder(appContext)
      .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
      .build()
    return EncryptedSharedPreferences.create(
      appContext,
      PREFS_FILE_NAME,
      masterKey,
      EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
      EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    val account = call.argument<String>("account")?.takeIf { it.isNotEmpty() } ?: DEFAULT_ACCOUNT
    try {
      when (call.method) {
        "read" -> result.success(prefs().getString(account, null))
        "write" -> {
          val value = call.argument<String>("value")
          if (value == null) {
            result.error("invalid_args", "value missing", null)
            return
          }
          prefs().edit().putString(account, value).apply()
          result.success(null)
        }
        "delete" -> {
          prefs().edit().remove(account).apply()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("storage_failed", e.message, null)
    }
  }
}
