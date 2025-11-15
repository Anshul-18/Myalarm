package com.example.alarm_app

import android.app.Activity
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "flutter_alarmapp/ringtone"
    private val ALARM_CHANNEL = "flutter_alarmapp/alarm"
    private val RINGTONE_PICKER_REQUEST = 999
    private var pendingResult: MethodChannel.Result? = null
    private var alarmChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Ringtone picker channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickRingtone") {
                pendingResult = result
                val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select Alarm Sound")
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                
                val currentRingtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                intent.putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, currentRingtone)
                
                startActivityForResult(intent, RINGTONE_PICKER_REQUEST)
            } else {
                result.notImplemented()
            }
        }
        
        // Alarm control channel
        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val timeInMillis = call.argument<Long>("timeInMillis") ?: 0L
                    val displayTime = call.argument<String>("time") ?: ""
                    scheduleAlarmWithManager(id, timeInMillis, displayTime)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarmWithManager(id)
                    result.success(true)
                }
                "stopAlarm" -> {
                    AlarmReceiver.stopAlarm()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Check if opened from alarm trigger
        handleAlarmTrigger(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAlarmTrigger(intent)
    }

    private fun handleAlarmTrigger(intent: Intent?) {
        if (intent?.getBooleanExtra("alarm_triggered", false) == true) {
            val alarmId = intent.getIntExtra("alarm_id", 0)
            val alarmTime = intent.getStringExtra("alarm_time") ?: ""
            
            // Notify Flutter to show alarm ringing page
            alarmChannel?.invokeMethod("showAlarmRinging", mapOf(
                "alarmId" to alarmId,
                "time" to alarmTime
            ))
        }
    }

    private fun scheduleAlarmWithManager(id: Int, timeInMillis: Long, displayTime: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        intent.putExtra("alarm_id", id)
        intent.putExtra("alarm_time", displayTime)
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
            }
            Log.d("MainActivity", "Alarm scheduled for ID: $id at $timeInMillis")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error scheduling alarm: ${e.message}")
        }
    }

    private fun cancelAlarmWithManager(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == RINGTONE_PICKER_REQUEST && pendingResult != null) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                if (uri != null) {
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
