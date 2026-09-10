import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String trackingUrl =
    "https://trackme.joizone.com/attendance/track_location.php";

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  print("======================================");
  print("🚀 TRACK ME BACKGROUND SERVICE STARTED");
  print("======================================");

  // --------------------------------------------------
  // ANDROID FOREGROUND SERVICE
  // --------------------------------------------------
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: "Track Me",
      content: "Location tracking is running",
    );
  }

  // --------------------------------------------------
  // SHARED PREFERENCES
  // --------------------------------------------------
  final prefs = await SharedPreferences.getInstance();

  String? attendanceId =
  prefs.getString('attendance_id');

  print("📌 Attendance ID: $attendanceId");

  // --------------------------------------------------
  // NO ACTIVE ATTENDANCE
  // --------------------------------------------------
  if (attendanceId == null ||
      attendanceId!.trim().isEmpty) {
    print("⚠️ No active attendance");
    print("🛑 Service stopped");

    service.stopSelf();
    return;
  }

  Position? lastPosition;

  // --------------------------------------------------
  // LOCATION TIMER
  // --------------------------------------------------
  Timer.periodic(
    const Duration(seconds: 60),
        (timer) async {
      try {
        print("");
        print("======================================");
        print("⏰ LOCATION TIMER");
        print("======================================");

        // Always read latest attendance ID
        attendanceId =
            prefs.getString('attendance_id');

        print(
          "📌 Current Attendance ID: $attendanceId",
        );

        // ------------------------------------------------
        // PUNCH OUT CHECK
        // ------------------------------------------------
        if (attendanceId == null ||
            attendanceId!.trim().isEmpty) {
          print(
            "🛑 No attendance ID - Punch Out completed",
          );

          timer.cancel();
          service.stopSelf();

          return;
        }

        // ------------------------------------------------
        // LOCATION SERVICE CHECK
        // ------------------------------------------------
        final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          print("❌ Location service is OFF");
          return;
        }

        // ------------------------------------------------
        // PERMISSION CHECK
        // ------------------------------------------------
        LocationPermission permission =
        await Geolocator.checkPermission();

        if (permission ==
            LocationPermission.denied) {
          permission =
          await Geolocator.requestPermission();
        }

        if (permission ==
            LocationPermission.denied) {
          print(
            "❌ Location permission denied",
          );
          return;
        }

        if (permission ==
            LocationPermission.deniedForever) {
          print(
            "❌ Location permission permanently denied",
          );
          return;
        }

        // ------------------------------------------------
        // GET CURRENT LOCATION
        // ------------------------------------------------
        final Position pos =
        await Geolocator.getCurrentPosition(
          desiredAccuracy:
          LocationAccuracy.medium,
        );

        print(
          "📍 Current Location: "
              "${pos.latitude}, ${pos.longitude}",
        );

        // ------------------------------------------------
        // DISTANCE FILTER
        // ------------------------------------------------
        if (lastPosition != null) {
          final double distance =
          Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );

          print(
            "📏 Movement: "
                "${distance.toStringAsFixed(2)} meters",
          );

          if (distance < 25) {
            print(
              "⏩ Location skipped - movement < 25m",
            );

            return;
          }
        }

        // Save latest position
        lastPosition = pos;

        // ------------------------------------------------
        // SEND LOCATION
        // ------------------------------------------------
        print("📡 Sending location...");

        final response = await http
            .post(
          Uri.parse(trackingUrl),
          body: {
            "attendance_id":
            attendanceId!,
            "lat":
            pos.latitude.toString(),
            "lng":
            pos.longitude.toString(),
            "status": "active",
          },
        )
            .timeout(
          const Duration(seconds: 30),
        );

        print(
          "🌐 HTTP Status: "
              "${response.statusCode}",
        );

        print(
          "✅ Server Response: "
              "${response.body}",
        );

        print(
          "======================================",
        );
      } catch (e, stackTrace) {
        print(
          "======================================",
        );

        print(
          "❌ LOCATION TRACKING ERROR",
        );

        print("Error: $e");

        print(
          "StackTrace: $stackTrace",
        );

        print(
          "======================================",
        );
      }
    },
  );

  // --------------------------------------------------
  // APP REMOVED FROM RECENT APPS
  // --------------------------------------------------
  service.on('onTaskRemoved').listen(
        (event) async {
      print(
        "======================================",
      );

      print(
        "⚠️ APP REMOVED FROM RECENT APPS",
      );

      print(
        "======================================",
      );

      try {
        final prefs =
        await SharedPreferences.getInstance();

        final String? savedAttendanceId =
        prefs.getString('attendance_id');

        print(
          "📌 Saved Attendance ID: "
              "$savedAttendanceId",
        );

        // ----------------------------------------------
        // ACTIVE ATTENDANCE
        // ----------------------------------------------
        if (savedAttendanceId != null &&
            savedAttendanceId.trim().isNotEmpty) {
          print(
            "✅ Active attendance found",
          );

          print(
            "🔄 Restarting background service...",
          );

          final bgService =
          FlutterBackgroundService();

          final bool running =
          await bgService.isRunning();

          print(
            "📡 Service running: $running",
          );

          if (!running) {
            await bgService.startService();

            print(
              "🚀 Background service restarted",
            );
          } else {
            print(
              "✅ Background service is already running",
            );
          }
        } else {
          // --------------------------------------------
          // NO ATTENDANCE
          // --------------------------------------------
          print(
            "⚠️ No active attendance",
          );

          print(
            "🛑 Service will NOT restart",
          );
        }
      } catch (e) {
        print(
          "❌ Restart error: $e",
        );
      }

      print(
        "======================================",
      );
    },
  );

  // --------------------------------------------------
  // STOP SERVICE
  // --------------------------------------------------
  service.on('stopService').listen(
        (event) {
      print(
        "======================================",
      );

      print(
        "🛑 STOP SERVICE EVENT",
      );

      print(
        "======================================",
      );

      service.stopSelf();
    },
  );
}