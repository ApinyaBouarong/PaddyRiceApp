package com.example.paddy_rice

import io.flutter.embedding.android.FlutterActivity
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

// สำหรับ MainActivity ใช้โค้ดที่เคยแนะนำไปก่อนหน้า
class MainActivity : FlutterActivity() {
    // เพิ่ม Method Channel ตามที่เคยแนะนำ
}

// ย้ายไปไฟล์แยกต่างหาก เช่น MyFirebaseMessagingService.kt
class MyFirebaseMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "MyFirebaseMessaging"
    }

    // Handle new token
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed token: $token")
        sendRegistrationToServer(token)
    }

    // Handle incoming messages
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "Message received: ${remoteMessage.data}")
        
        // สามารถประกาศการแจ้งเตือนหรือส่งข้อมูลต่อไปได้
    }

    private fun sendRegistrationToServer(token: String) {
        // ส่ง token ไปยังเซิร์ฟเวอร์หรือทำการบันทึก
        Log.d(TAG, "Sending token to server: $token")
        // เพิ่มโค้ดส่ง token ไปยังเซิร์ฟเวอร์ของคุณ
    }
}