package com.example.joizone

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import okhttp3.*
import java.io.IOException

class MainActivity: FlutterActivity() {

//    override fun onDestroy() {
//        super.onDestroy()
//
//        Log.e("AUTO_PUNCH", "App destroyed")
//
//        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
//
//        val attendanceId = prefs.getString("flutter.attendance_id", null)
//        val uid = prefs.getString("flutter.uid", null)
//        val cid = prefs.getString("flutter.cid", null)
//
//        if (attendanceId != null && uid != null && cid != null) {
//
//            val client = OkHttpClient()
//
//            val formBody = FormBody.Builder()
//                .add("action","punch_out")
//                .add("status","Present")
//                .add("uid",uid)
//                .add("cid",cid)
//                .add("lat","0")
//                .add("lng","0")
//                .add("remark","Auto punch Out - App closed")
//                .add("image","NA")
//                .build()
//
//            val request = Request.Builder()
//                .url("https://fms.bizipac.com/apinew/attendance/attendance_punch_out.php?attendance_id=$attendanceId")
//                .post(formBody)
//                .build()
//
//            client.newCall(request).enqueue(object : Callback {
//
//                override fun onFailure(call: Call, e: IOException) {
//                    Log.e("AUTO_PUNCH", "API FAILED: ${e.message}")
//                }
//
//                override fun onResponse(call: Call, response: Response) {
//
//                    try {
//
//                        Log.e("AUTO_PUNCH", "API SUCCESS")
//
//                        val body = response.body?.string()
//                        Log.e("AUTO_PUNCH", "Response: $body")
//
//                    } catch (e: Exception) {
//
//                        Log.e("AUTO_PUNCH", "Error reading response")
//
//                    } finally {
//
//                        response.close()
//
//                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
//
//                        val editor = prefs.edit()
//
//                        editor.remove("flutter.attendance_id")
//
//                        val result = editor.commit()
//
//                        Log.e("AUTO_PUNCH", "Attendance Removed: $result")
//                    }
//                }
//            })
//        }
//    }
}