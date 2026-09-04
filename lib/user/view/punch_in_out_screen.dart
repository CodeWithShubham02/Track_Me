import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/admin/view/login_screen.dart';
import 'package:permission_handler/permission_handler.dart' hide Permission;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../handller/encription_decription.dart';

class PunchInOutScreen extends StatefulWidget {
  UserModel userModel;

  PunchInOutScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<PunchInOutScreen> createState() => _PunchInOutScreenState();
}

class _PunchInOutScreenState extends State<PunchInOutScreen> {
  bool isLoading = false;

  Position? currentPosition;
  double? currentDistance;

  final TextEditingController remarkCtrl = TextEditingController();
  XFile? capturedImage;

  TimeOfDay? shiftStart;
  TimeOfDay? shiftEnd;
  late double officeRange;
  DateTime? dateOfJoining;
  String? attendanceId;
  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    print("-----punch------");
    print(widget.userModel.uid);
    print(widget.userModel.cid);
    print("--------");
    loadLiveLocation();

    officeRange =
        double.tryParse(widget.userModel.branchDistance.toString()) ?? 0.0;

    shiftStart = parseTime(widget.userModel.shiftStart);
    shiftEnd   = parseTime(widget.userModel.shiftEnd);

    dateOfJoining =
        DateTime.tryParse(widget.userModel.dateOfJoining.toString());
  }


  // ---------------- LOCATION ----------------
  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location service disabled';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistance(
      double officeLat,
      double officeLng,
      double userLat,
      double userLng,
      ) {
    return Geolocator.distanceBetween(
      officeLat,
      officeLng,
      userLat,
      userLng,
    );
  }
  double toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.parse(value.toString());
  }

  Future<void> loadLiveLocation() async {
    final officeLat = toDouble(widget.userModel.branchLat);
    final officeLng = toDouble(widget.userModel.branchLong);

    final pos = await getCurrentLocation();

    final dist = calculateDistance(
      officeLat,
      officeLng,
      pos.latitude,
      pos.longitude,
    );

    setState(() {
      currentPosition = pos;
      debugPrint("Location error: ${currentPosition!.latitude}");
      debugPrint("Location error: ${currentPosition!.longitude}");
      currentDistance = dist;
    });
    await getAddressFromLatLng(pos); // 🔥 Address convert
  }
  String address = "Fetching address...";

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;

      setState(() {
        address =
        "${place.name}, ${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea}, "
            "${place.postalCode}";
      });
    } catch (e) {
      debugPrint("Address error: $e");
      setState(() {
        address = "Address not found";
      });
    }
  }


  // ---------------- SHIFT ----------------


  TimeOfDay? parseTime(String? time) {
    try {
      if (time == null || time.isEmpty) return null;

      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  bool isWithinShift() {
    if (shiftStart == null || shiftEnd == null) {
      return false; // or handle properly
    }

    final now = TimeOfDay.now();

    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    return toMinutes(now) >= toMinutes(shiftStart!) &&
        toMinutes(now) <= toMinutes(shiftEnd!);
  }

  // ---------------- IMAGE ----------------\
  //photo
  bool isLoadingPhoto = false;
  File? photo;          // Mobile
  Uint8List? webPhoto; // Web
  String? photoUrl;     // Uploaded URL

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  Future<String> getAddressFromLatLng1(double lat, double lng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        return [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].where((e) => e != null && e!.isNotEmpty).join(', ');
      }
      return 'Address not found';
    } catch (e) {
      return 'Address error';
    }
  }
  Future<Uint8List> addWatermark({
    required Uint8List imageBytes,
    required double lat,
    required double lng,
  }) async {
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception("Unable to decode image");
    }

    final dateTime =
    DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());

    final address = await getAddressFromLatLng1(lat, lng);

    final watermarkText = '$address\n$dateTime';

    final font = img.arial48;
    const padding = 20;

    final lines = watermarkText.split('\n');
    final maxLineLength =
    lines.map((e) => e.length).reduce((a, b) => a > b ? a : b);

    const approxCharWidth = 28;
    const approxLineHeight = 55;

    final textWidth = maxLineLength * approxCharWidth;
    final textHeight = lines.length * approxLineHeight;

    final x = image.width - textWidth - padding;
    final y = image.height - textHeight - padding;

    img.fillRect(
      image,
      x1: x - 15,
      y1: y - 15,
      x2: x + textWidth + 15,
      y2: y + textHeight + 15,
      color: img.ColorRgb8(0, 0, 0),
    );

    img.drawString(
      image,
      watermarkText,
      font: font,
      x: x,
      y: y,
      color: img.ColorRgb8(255, 255, 255),
    );

    return Uint8List.fromList(
      img.encodeJpg(image, quality: 85),
    );
  }

  final ImagePicker _picker = ImagePicker();
  Future<String?> pickImagePhoto1(ImageSource source) async {
    try {
      isTrackingActive = false;
      locationTimer?.cancel();

      setState(() => isLoadingPhoto = true);

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked == null) {
        isTrackingActive = true;
        startLocationTracking();
        return null;
      }

      debugPrint("Image Path: ${picked.path}");

      final rawBytes = await picked.readAsBytes();
      debugPrint("Image Size: ${rawBytes.length}");

      final position = await _getCurrentLocation();
      debugPrint("Location: ${position.latitude}, ${position.longitude}");

      final watermarkedBytes = await addWatermark(
        imageBytes: rawBytes,
        lat: position.latitude,
        lng: position.longitude,
      );

      debugPrint("Watermark Added");

      final fileName =
          "uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final imageUrl = await uploadImageToS3(
        imageBytes: watermarkedBytes,
        bucket: "joizone-s3",
        objectKey: fileName,
      );

      debugPrint("Upload Success: $imageUrl");

      setState(() {
        photoUrl = imageUrl;
      });

      isTrackingActive = true;
      startLocationTracking();

      return imageUrl;
    } catch (e, stackTrace) {
      debugPrint("Image Upload Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      isTrackingActive = true;
      startLocationTracking();

      return null;
    } finally {
      if (mounted) {
        setState(() => isLoadingPhoto = false);
      }
    }
  }

  void deletePhoto() {
    setState(() {
      photo = null;
      webPhoto = null;
      photoUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Photo deleted")),
    );
  }
  Future<String> uploadImageToS3({
    required Uint8List imageBytes,
    required String bucket,
    required String objectKey,
    String region = 'ap-south-1',
  }) async {
    final s3 = S3(
      region: region,
      credentials: AwsClientCredentials(
        accessKey: decryptFMS(
          "TohPtOvObC8NnBOp/1BM30tSr97U803JZ+gqI3Jf4uM=",
          "QWRTEfnfdys635",
        ),
        secretKey: decryptFMS(
          "Exz2WIEt2w1JRVZREvtIPeRX5Jti2p2mcHqs7Hh87/47BQidFAUAkLOxlzYFlctw",
          "QWRTEfnfdys635",
        ),
      ),
    );

    await s3.putObject(
      bucket: bucket,
      key: objectKey,
      body: imageBytes,
      contentLength: imageBytes.length,
      contentType: 'image/jpeg',
    );

    return "https://$bucket.s3.$region.amazonaws.com/$objectKey";
  }



  // ---------------- DATE ----------------
  String todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // ---------------- PUNCH IN ----------------
  DateTime _timeToToday(String hhmm) {
    final parts = hhmm.split(':');
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Map<String, dynamic>  getPunchStatus({
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required String department,
  }) {
    final now = DateTime.now();

    DateTime start = shiftStart;
    DateTime end = shiftEnd;

    // 🔥 Handle Night Shift Properly
    if (end.isBefore(start)) {
      // Means shift crosses midnight
      if (now.isBefore(start)) {
        start = start.subtract(const Duration(days: 1));
      } else {
        end = end.add(const Duration(days: 1));
      }
    }

    final allowedStart = start.subtract(const Duration(minutes: 360));
    // final presentLimit = start.add(const Duration(minutes: 10));
    final onTimeLimit = start.add(Duration(minutes: 10));
    final halfDayLimit = start.add(Duration(hours: 2));
    // ❌ Too early
    if (now.isBefore(allowedStart)) {
      throw 'Punch allowed only after ${allowedStart.hour}:${allowedStart.minute.toString().padLeft(2, '0')}';
    }

    // ❌ Shift window over
    if (now.isAfter(end)) {
      throw 'Shift already ended';
    }
    /// 🔥 TEAM LEADER OVERRIDE
    if (department == 'Team Leader') {
      return {
        "status": "Present",
        "late": "On Time",
      };
    }
    // ✅ Late logic
    String status = "";
    String lateText = "";

    /// ✅ Early
    if (now.isBefore(start)) {
      status = "Present";
      lateText = "Early Punch";
    }

    /// ✅ On Time
    else if (now.isBefore(onTimeLimit)) {
      status = "Present";
      lateText = "On Time";
    }

    /// 🔥 Late
    else if (now.isBefore(halfDayLimit)) {
      status = "Present"; // 🔥 FIX

      Duration diff = now.difference(start);
      int hours = diff.inHours;
      int minutes = diff.inMinutes % 60;

      lateText = "Late";
    }

    /// ❗ Half Day
    else {
      status = "Present";
      lateText = "Half Day";
    }

    return {
      "status": status,
      "late": lateText,
    };
  }

  Future<void> checkGpsAndAutoPunchOut() async {
    // ❌ DO NOT RUN IF CAMERA IS OPEN
    if (!isTrackingActive) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && attendanceId != null) {
      await autoPunchOut("GPS turned off");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GPS OFF - Auto Punch Out")),
        );
      }
    }
  }
  Future<void> autoPunchOut(String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAttendanceId = prefs.getString('attendance_id');

      if (savedAttendanceId == null) return;

      await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/attendance_punch_out.php?attendance_id=$savedAttendanceId",
        ),
        body: {
          "action": "punch_out",
          "status": "Present",
          "uid": widget.userModel.uid,
          "cid": widget.userModel.cid,
          "lat": currentPosition?.latitude.toString() ?? "0",
          "lng": currentPosition?.longitude.toString() ?? "0",
          "remark": "GPS Turn Off - Auto Punch",
          "image": "NA",
        },
      );

      await stopLocationTracking();
      await prefs.remove('attendance_id');
      await prefs.remove('uid');
      await prefs.remove('cid');

      debugPrint("✅ Auto punch out done due to GPS OFF");
    } catch (e) {
      debugPrint("❌ Auto punch out failed: $e");
    }
  }
  bool isTrackingActive = false;

  Timer? locationTimer;
  Future<void> startLocationTracking() async {
    locationTimer?.cancel();
    isTrackingActive = true;

    locationTimer = Timer.periodic(
      const Duration(seconds: 60),
          (_) async {
        if (!isTrackingActive || attendanceId == null) return;
        try {
          await checkGpsAndAutoPunchOut();
          if (!isTrackingActive || attendanceId == null) return;
          final permission = await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            await Geolocator.requestPermission();
          }
          if (!isTrackingActive || attendanceId == null) return;
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // 🔐 FINAL SAFETY CHECK (CRITICAL)
          if (!isTrackingActive || attendanceId == null) return;

          final res = await http.post(
            Uri.parse(
              "http://15.206.209.30/attendance/track_location.php",
            ),
            body: {
              "attendance_id": attendanceId!,
              "lat": position.latitude.toString(),
              "lng": position.longitude.toString(),
              "status": "active",
            },
          );

          final data = jsonDecode(res.body);
          debugPrint("Track status: ${data['status']}");
        } catch (e) {
          debugPrint("Location update failed: $e");
        }
      },
    );
  }

  String? selectBranchName;

  Future<void> punchIn() async {
    // 1️⃣ Distance check
    if (currentDistance == null || currentDistance! > officeRange) {
      throw 'You are outside office radius';
    }

    // 2️⃣ Fetch employee shift from API
    final empRes = await http.post(
      Uri.parse("http://15.206.209.30/attendance/get_users.php"),
      body: {
        "uid": widget.userModel.uid,
        "cid": widget.userModel.cid,
      },
    );
    print("---user fetch");
    final empData = jsonDecode(empRes.body);
    print(empData);

    if (empData['status'] != true) {
      throw 'Employee not found';
    }

    DateTime shiftStart = _timeToToday(widget.userModel.shiftStart);
    DateTime shiftEnd = _timeToToday(widget.userModel.shiftEnd);

// Night shift fix
    if (shiftEnd.isBefore(shiftStart)) {
      shiftEnd = shiftEnd.add(const Duration(days: 1));
    }

    // 3️⃣ Decide Present / Late
    final status = getPunchStatus(
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      department: widget.userModel.departmentName,
    );
    print("-------------");
    print(status['status']);
    print(status['late']);
    print(status['late'].toString());
    print("-----------------");

    // 4️⃣ Call Punch-In API
    final res = await http.post(
      Uri.parse("http://15.206.209.30/attendance/attendance_punch_in.php"),
      body: {
        "uid": widget.userModel.uid,
        "cid": widget.userModel.cid,
        'status': status['status'],
        // ✅ FIXED
        "late":status['late'].toString(), // 0 ya 1
        "distance": currentDistance!.toString(),
        "department": widget.userModel.departmentName,
        "name": widget.userModel.fullName,
        //"office_name": widget.userModel.branchName,
        "office_name": selectBranchName.toString(),
        "shift_start": widget.userModel.shiftStart,
        "shift_end": widget.userModel.shiftEnd,
        "lat": currentPosition!.latitude.toString(),
        "lng": currentPosition!.longitude.toString(),
        "remark": remarkCtrl.text,
        "image":  photoUrl ?? "", // multipart later
      },
    );

    final data = jsonDecode(res.body);
    print("------------punch in api -------");
    print(res);
    print(data);
    if (data['status'] != true) {
      throw data['message'] ?? 'Punch In failed';
    }
    // 🔥 STORE attendance_id
    attendanceId = data['attendance_id'].toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendance_id', attendanceId!);
    await prefs.setString('uid', widget.userModel.uid);
    await prefs.setString('cid', widget.userModel.cid);

    final punchInTime = DateTime.now();

    await prefs.setString(
      'punch_in_time',
      punchInTime.toIso8601String(),
    );
    print("Attendance ID saved: $attendanceId");
    print(data);
    debugPrint("Attendance ID: $attendanceId");


    // 5️⃣ Start live location tracking

    startLocationTracking();
    // ▶️ START BACKGROUND SERVICE
    final service = FlutterBackgroundService();
    //await service.startService();
    bool isRunning = await service.isRunning();

    if (!isRunning) {
      service.startService();
    }
  }


  Future<void> stopLocationTracking() async {
    // 🚨 FIRST LINE (MOST IMPORTANT)
    isTrackingActive = false;

    locationTimer?.cancel();
    locationTimer = null;

    if (attendanceId == null) return;

    try {
      await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/track_location.php",
        ),
        body: {
          "attendance_id": attendanceId!,
          "status": "stop",
        },
      );
    } catch (e) {
      debugPrint("Stop tracking API error: $e");
    }

    FlutterBackgroundService().invoke('stopService');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('attendance_id');
    await prefs.clear();

    attendanceId = null;

    debugPrint("🛑 Tracking HARD stopped");
  }

  // ---------------- PUNCH OUT ----------------
  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
  void validatePunchOut({
    required DateTime shiftEnd,
  }) {
    final now = DateTime.now();

    if (now.isBefore(shiftEnd)) {
      throw 'Punch-out allowed only after '
          '${shiftEnd.hour}:${shiftEnd.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> punchOut() async {
    try {
      if (currentDistance == null || currentDistance! > officeRange) {
        throw 'Punch out allowed only inside office';
      }

      if (currentPosition == null) {
        throw "Location not ready";
      }

      final prefs = await SharedPreferences.getInstance();
      attendanceId = prefs.getString('attendance_id');

      if (attendanceId == null) {
        throw 'Already punched out.';
      }

      // final shiftEnd =
      // _timeToToday(widget.userModel.shiftEnd);   // "19:00"
      // validatePunchOut(shiftEnd: shiftEnd);

      final res = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/attendance_punch_out.php"
              "?attendance_id=$attendanceId",
        ),
        body: {
          "action": "punch_out",
          "status": "Present",
          "uid": widget.userModel.uid,
          "cid": widget.userModel.cid,
          "lat": currentPosition!.latitude.toString(),
          "lng": currentPosition!.longitude.toString(),
          "remark": remarkCtrl.text,
          "image":  photoUrl ?? "",
        },
      );

      final data = jsonDecode(res.body);

      if (data['status'] != true) {
        throw data['message'] ?? 'Punch Out failed';
      }

      // 🔥 STOP GPS
      await stopLocationTracking();
      // ❌ REMOVE attendance_id
      await prefs.remove('attendance_id');
      attendanceId = null;
      await prefs.remove('uid');
      await prefs.remove('cid');
      await prefs.clear();

      // 🛑 STOP SERVICE
      FlutterBackgroundService().invoke('stopService');
      // ✅ SUCCESS SNACKBAR
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Punch out successful'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 4));
      Get.offAll(() => LoginScreen());

    } catch (e) {
      // ❌ ERROR SNACKBAR
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String convertTo12Hour(String time) {
    try {
      final parsedTime = DateFormat("HH:mm").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Punch In / Out",style: TextStyle(color: Colors.white,fontSize: 16,fontFamily: 'impact'),),
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: 350,
              child: currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    currentPosition!.latitude,
                    currentPosition!.longitude,
                  ),
                  zoom: 14,
                ),
                myLocationEnabled: true,
              ),
            ),

            Text(
              currentDistance == null
                  ? ""
                  : "Distance: ${currentDistance!.toStringAsFixed(0)} meters",
              style: TextStyle(
                color: currentDistance != null &&
                    currentDistance! <= officeRange
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Shift Time: "),
                Text(convertTo12Hour(widget.userModel.shiftStart)),
                Text(" - "),
                Text(convertTo12Hour(widget.userModel.shiftEnd)),
              ],
            ),
            // Card(
            //   margin: const EdgeInsets.all(12),
            //   child: Padding(
            //     padding: const EdgeInsets.all(12),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text("Current Location",
            //             style: TextStyle(fontWeight: FontWeight.bold)),
            //         const SizedBox(height: 6),
            //         Text(currentPosition == null
            //             ? "Fetching..."
            //             : "Lat: ${currentPosition!.latitude}\nLng: ${currentPosition!.latitude}"),
            //         const SizedBox(height: 6),
            //         Text(
            //           currentDistance == null
            //               ? ""
            //               : "Distance: ${currentDistance!.toStringAsFixed(0)} meters",
            //           style: TextStyle(
            //             color: currentDistance != null &&
            //                 currentDistance! <= officeRange
            //                 ? Colors.green
            //                 : Colors.red,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  currentPosition == null
                      ? "Fetching location..."
                      : address,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: DropdownButtonFormField<String>(
                value: selectBranchName,
                decoration: const InputDecoration(
                  hint: Row(
                    children: [
                      Text("Select Branch"),
                      Text(
                        "*",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),

                items: widget.userModel.branchMap
                    .map((branch) {
                  final name = branch['branch_name']?.toString() ?? '';

                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                })
                    .where((item) => item.value != null && item.value!.isNotEmpty)
                    .toList(),

                onChanged: (val) {
                  setState(() {
                    selectBranchName = val;
                  });

                  print("Selected Branch: $selectBranchName");
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: remarkCtrl,
                decoration: const InputDecoration(
                  labelText: "Remark",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            photoUrl != null
                ? const SizedBox.shrink()
                : isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  isLoading = true; // 🔥 Start loading
                });

                final imageUrl =
                await pickImagePhoto1(ImageSource.camera);

                print("Uploaded Image URL: $imageUrl");

                setState(() {
                  isLoading = false; // ✅ Stop loading
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture Image"),
            ),
            if (photo != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Image.file(
                  File(photo!.path),
                  height: 100,
                  width: 100,
                ),
              )
            else if (photoUrl != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Image.network(
                  photoUrl!,
                  height: 100,
                  width: 100,
                ),
              ),
            const SizedBox(height: 10),

            isLoading
                ? const CircularProgressIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                photoUrl==null?SizedBox.shrink():ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() => isLoading = true);
                      await punchIn();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text("Punch In Done")));
                      Get.back(result: true);
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // 🔥 Punch out color
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Punch In"),
                ),

                const SizedBox(height: 5),

                photoUrl==null?SizedBox.shrink():ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() => isLoading = true);
                      await punchOut();
                      // ScaffoldMessenger.of(context)
                      //     .showSnackBar(const SnackBar(content: Text("Punch Out Done")));

                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }finally {
                      setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // 🔥 Punch out color
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Punch Out"),
                ),

              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}