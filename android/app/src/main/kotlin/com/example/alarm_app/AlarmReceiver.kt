package com.example.alarm_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.media.Ringtone
import android.media.AudioManager
import android.os.Build
import android.app.KeyguardManager
import android.os.PowerManager
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        var ringtone: Ringtone? = null
        private var wakeLock: PowerManager.WakeLock? = null
        
        fun stopAlarm() {
            ringtone?.stop()
            ringtone = null
            wakeLock?.release()
            wakeLock = null
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "Alarm triggered!")
        
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val alarmTime = intent.getStringExtra("alarm_time") ?: ""
        
        // Acquire wake lock to wake up the screen
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
            PowerManager.ON_AFTER_RELEASE,
            "AlarmApp:AlarmWakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes max
        
        // Play alarm sound
        try {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ringtone = RingtoneManager.getRingtone(context, alarmUri)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ringtone?.isLooping = true
            }
            
            ringtone?.play()
            Log.d("AlarmReceiver", "Playing alarm sound")
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "Error playing alarm: ${e.message}")
        }
        
        // Launch the app with alarm data
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("alarm_triggered", true)
            putExtra("alarm_id", alarmId)
            putExtra("alarm_time", alarmTime)
        }
        context.startActivity(launchIntent)
    }
}
