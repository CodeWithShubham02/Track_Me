import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ApiUrls {
  static const base = "http://15.206.209.30/attendance/";
  static const punchIn = "${base}attendance_punch_in.php";
  static const punchOut = "${base}attendance_punch_out.php";
  static const breakStart = "${base}break_start.php";
  static const breakEnd = "${base}break_end.php";
  static const trackLocation = "${base}track_location.php";
}

class AttendanceService {
  Timer? _locationTimer;
  String attendanceId = "";

  // ---------------- LOCATION PERMISSION ----------------
  Future<Position> _getPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw "Location permission denied";
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ---------------- PUNCH IN ----------------
  Future<void> punchIn({
    required String uid,
    required String cid,
    required String remark,
    XFile? image,
  }) async {
    final pos = await _getPosition();

    final res = await http.post(
      Uri.parse(ApiUrls.punchIn),
      body: {
        "uid": uid,
        "cid": cid,
        "lat": pos.latitude.toString(),
        "lng": pos.longitude.toString(),
        "remark": remark,
      },
    );

    final data = jsonDecode(res.body);
    if (data["status"] != true) {
      throw data["message"] ?? "Punch In failed";
    }

    attendanceId = data["attendance_id"].toString();
    _startTracking();
  }

  // ---------------- PUNCH OUT ----------------
  Future<void> punchOut(String remark) async {
    if (attendanceId.isEmpty) return;

    final pos = await _getPosition();

    await http.post(
      Uri.parse(ApiUrls.punchOut),
      body: {
        "attendance_id": attendanceId,
        "lat": pos.latitude.toString(),
        "lng": pos.longitude.toString(),
        "remark": remark,
      },
    );

    _stopTracking();
    attendanceId = "";
  }

  // ---------------- BREAK ----------------
  Future<void> startBreak() async {
    await http.post(Uri.parse(ApiUrls.breakStart),
        body: {"attendance_id": attendanceId});
  }

  Future<void> endBreak() async {
    await http.post(Uri.parse(ApiUrls.breakEnd),
        body: {"attendance_id": attendanceId});
  }

  // ---------------- LOCATION TRACK ----------------
  void _startTracking() {
    _locationTimer?.cancel();
    _locationTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _sendLocation());
  }

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _sendLocation() async {
    if (attendanceId.isEmpty) return;
    final pos = await _getPosition();

    await http.post(
      Uri.parse(ApiUrls.trackLocation),
      body: {
        "attendance_id": attendanceId,
        "lat": pos.latitude.toString(),
        "lng": pos.longitude.toString(),
      },
    );
  }

  void dispose() {
    _stopTracking();
  }
}
