import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: "Tracking Location",
      content: "Location is running in background",
    );
  }

  final prefs = await SharedPreferences.getInstance();
  String? attendanceId = prefs.getString('attendance_id');

  if (attendanceId == null || attendanceId.isEmpty) {
    service.stopSelf();
    return;
  }

  Position? lastPosition;

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    try {
      attendanceId = prefs.getString('attendance_id');

      if (attendanceId == null || attendanceId!.isEmpty) {
        timer.cancel();
        service.stopSelf();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      /// 🔥 Distance Filter (50m)
      if (lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );

        if (distance < 50) {
          print("⏩ Skipped (<50m)");
          return;
        }
      }

      lastPosition = pos;

      print("📡 Sending: ${pos.latitude}, ${pos.longitude}");

      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/track_location.php"),
        body: {
          "attendance_id": attendanceId!,
          "lat": pos.latitude.toString(),
          "lng": pos.longitude.toString(),
          "status": "active",
        },
      );

      print("✅ Response: ${response.body}");

    } catch (e) {
      print("❌ Error: $e");
    }
  });

  /// 🔥 Restart if killed
  service.on('onTaskRemoved').listen((event) async {
    final bgService = FlutterBackgroundService();
    bgService.startService(); // ✅ correct object
  });
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}