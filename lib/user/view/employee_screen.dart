import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joizone/chatbot/chatbot_screen.dart';
import 'package:joizone/user/view/notification_screen.dart';
import 'package:joizone/user/view/update_user_shift_screen.dart';
import 'package:joizone/user/view/user_live_location_screen.dart';
import 'package:joizone/user/view/userid_card_widget.dart';
import 'package:joizone/user/view/users_performance_screen.dart';
import 'package:joizone/user/view/video_dialog.dart';
import 'package:joizone/user/view/video_dialogtl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../admin/dynamic_form/dynamic_form_screen.dart';
import '../../admin/model/user_model.dart';
import '../../admin/view/login_screen.dart';
import '../../services/fcm_service.dart';
import '../../services/get_server_key.dart';
import '../../services/notification_service.dart';
import '../controller/start_break_controller.dart';
import '../view/punch_in_out_screen.dart';
import '../view/user_attendance_screen.dart';
import '../view/airport_form_screen.dart';
import '../view/submit_form_screen.dart';
import '../view/get_report_kiosk_screen.dart';
import '../view/google_location_screen.dart';
import '../view/attendance_screen.dart';
import 'get_all_dynamic_form.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final UserModel userModel;

  const EmployeeHomeScreen({super.key, required this.userModel});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String? attendanceId;
  Position? currentPosition;

  Timer? gpsTimer;
  StreamSubscription<List<ConnectivityResult>>? connectivitySub;

  bool internetDialogShown = false;

  /* ---------------- INIT ---------------- */
  DateTime _currentTime = DateTime.now();
  //user permission allow
  NotificationService notificationService = NotificationService();
  late ConfettiController _controllerTopCenter;

  ///dynamic form
  List<dynamic> forms = [];
  bool isLoadingForms = false;
  Future<void> getCompanyForms() async {
    setState(() {
      isLoadingForms = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_company_forms.php?cid=${widget.userModel.cid}",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          forms = (json["data"] as List)
              .where((form) => form["status"] == "1")
              .toList();
        } else {
          forms = [];
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoadingForms = false;
    });
  }
  @override
  void initState() {
    getCompanyForms();
    _controllerTopCenter =
        ConfettiController(duration: const Duration(seconds: 5));
    super.initState();
    _controllerTopCenter.play();
    notificationService.requestNotificationPermission();
    notificationService.getDeviceToken();
    //FCMService.firebaseInit();
    // notificationService.initLocalNotification(context);
    //
    notificationService.firebaseInit(context);
    //
    notificationService.setupInteractMessage(context);
    loadAttendanceId();

    loadLiveLocation();
    startGpsMonitor();
    startInternetMonitor(); // 🔥 ADD THIS
    syncOfflinePunchOutIfAny();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }
  @override
  void dispose() {
    autoCloseTimer?.cancel();
    gpsTimer?.cancel();
    connectivitySub?.cancel();
    _timer?.cancel();
    super.dispose();
    autoCloseTimer = null;
    gpsTimer = null;
    connectivitySub = null;
    _timer = null;
    _controllerTopCenter.dispose();
  }


  /* ---------------- INTERNET MONITOR ---------------- */
  Timer? internetOffTimer;
  void startInternetMonitor() {
    connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasInternet = await hasRealInternet();

      /// 🔴 INTERNET OFF
      if (!hasInternet && attendanceId != null) {
        // agar pehle se timer nahi chal raha
        if (internetOffTimer == null) {
          internetOffTimer = Timer(const Duration(minutes: 5), () async {
            final stillNoInternet = await hasRealInternet();

            if (!stillNoInternet &&
                attendanceId != null &&
                !internetDialogShown) {
              internetDialogShown = true;

              await autoPunchOutInternet(
                "Internet turned off - Auto Punch Out",
              );

              if (!mounted) return;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    title: Text("Internet Off"),
                    content: Text(
                      "Internet was off for 5 minutes.\n"
                          "You have been auto punched out.",
                    ),
                  ),
                );
              });
            }

            internetOffTimer = null; // reset timer
          });
        }
      }

      /// 🟢 INTERNET BACK
      if (hasInternet) {
        internetDialogShown = false;

        // agar timer chal raha tha toh cancel karo
        if (internetOffTimer != null) {
          internetOffTimer!.cancel();
          internetOffTimer = null;
        }

        await syncOfflinePunchOutIfAny();
      }
    });
  }

  Future<bool> hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /* ---------------- LOCAL OFFLINE SAVE ---------------- */

  Future<void> saveLocalPunchOut(String reason) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("offline_punchout_pending", true);
    await prefs.setString("offline_attendance_id", attendanceId ?? "");
    await prefs.setString("offline_reason", reason);
    await prefs.setString(
        "offline_lat", currentPosition?.latitude.toString() ?? "0");
    await prefs.setString(
        "offline_lng", currentPosition?.longitude.toString() ?? "0");
    await prefs.setString(
        "offline_time", DateTime.now().toIso8601String());

    debugPrint("📦 Offline punch-out saved");
  }

  /* ---------------- OFFLINE SYNC ---------------- */

  Future<void> syncOfflinePunchOutIfAny() async {
    final prefs = await SharedPreferences.getInstance();

    final pending = prefs.getBool("offline_punchout_pending") ?? false;
    if (!pending) return;

    final savedAttendanceId =
        prefs.getString("offline_attendance_id") ?? "";
    if (savedAttendanceId.isEmpty) return;

    final internet = await hasRealInternet();
    if (!internet) return;

    final res = await http.post(
      Uri.parse(
        "http://15.206.209.30/attendance/attendance_punch_out.php?attendance_id=$savedAttendanceId",
      ),
      body: {
        "action": "punch_out",
        "status": "Present",
        "remark": prefs.getString("offline_reason") ?? "",
        "lat": prefs.getString("offline_lat") ?? "0",
        "lng": prefs.getString("offline_lng") ?? "0",
        "image": "NA",
      },
    );

    if (res.statusCode == 200) {
      await prefs.remove("offline_punchout_pending");
      await prefs.remove("offline_attendance_id");
      await prefs.remove("offline_reason");
      await prefs.remove("offline_lat");
      await prefs.remove("offline_lng");
      await prefs.remove("offline_time");

      await prefs.remove("attendance_id");

      FlutterBackgroundService().invoke('stopService');

      await stopLocationTracking();
// 🔥 ADD NAVIGATION HERE ALSO
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
        );
      }
      await sendFcmMessageWithOAuth(
        widget.userModel.userToken,
        "Internet turned off - Auto Punch Out",
        "Aap Internet  off kiye the kuch time ke liye, isliye system ne aapka punch-out automatically kar diya hai.",
      );
      debugPrint("✅ Offline punch-out synced");
    }
  }

  /* ---------------- AUTO PUNCH OUT ---------------- */
  bool isAutoPunchingInternet = false;
  Future<void> autoPunchOutInternet(String reason) async {
    if (isAutoPunchingInternet) return;

    isAutoPunchingInternet = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAttendanceId = prefs.getString('attendance_id');
      if (savedAttendanceId == null) return;

      final internet = await hasRealInternet();
      bool success = false;

      if (internet) {
        try {
          final response = await http.post(
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
              "remark": reason,
              "image": "NA",
            },
          );

          final data = jsonDecode(response.body);

          if (data['status'] == true) {
            success = true;
          } else {
            await saveLocalPunchOut(reason);
          }

        } catch (_) {
          await saveLocalPunchOut(reason);
        }

      } else {
        await saveLocalPunchOut(reason);
      }

      if (success) {
        await prefs.remove('attendance_id');

        FlutterBackgroundService().invoke('stopService');

        await stopLocationTracking();

        if (mounted) {
          setState(() => attendanceId = null);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
          );
        }
      }

    } finally {
      isAutoPunchingInternet = false;
    }
  }

  /* ---------------- ATTENDANCE ID ---------------- */

  Future<void> loadAttendanceId() async {
    final prefs = await SharedPreferences.getInstance();
    attendanceId = prefs.getString('attendance_id');
    if (mounted) setState(() {});
  }
  /* ---------------- LOGOUT ---------------- */
  Future<void> showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // outside click se close na ho
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [

            // ❌ Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog close
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            // ✅ OK Button
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // dialog close first
                await logout(context);  // then logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }


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

  Future<void> loadLiveLocation() async {
    try {
      final pos = await getCurrentLocation();
      if (!mounted) return;
      setState(() => currentPosition = pos);
    } catch (e) {
      debugPrint("Location  s error: $e");
    }
  }

  /* ---------------- GPS MONITOR ---------------- */

  void startGpsMonitor() {
    gpsTimer?.cancel();

    gpsTimer = Timer.periodic(
      const Duration(seconds: 60),
          (_) async {
        await  loadAttendanceId();
        await loadLiveLocation(); // update currentPosition
        await checkGpsAndAutoPunchOut();
        await checkDistanceAndAutoPunchOut(); // 🔥 radius check
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      },
    );
  }

  Future<void> checkGpsAndAutoPunchOut() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && attendanceId != null) {

      await autoPunchOut("GPS Turn Off - Auto Punch");

      Get.offAll(()=>LoginScreen());
    }
  }

  /* ---------------- AUTO PUNCH OUT ---------------- */

  Future<void> autoPunchOut(String reason) async {
    try {
      await sendFcmMessageWithOAuth(
        widget.userModel.userToken,
        "$reason",
        "Aap allowed office location/radius se bahar chale gaye the, isliye system ne aapka punch-out automatically kar diya hai.",
      );
      final prefs = await SharedPreferences.getInstance();
      final savedAttendanceId = prefs.getString('attendance_id');

      if (savedAttendanceId == null) {
        debugPrint("⚠️ No attendance_id found");
        return;
      }

      final response = await http.post(
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
          "remark": reason,
          "image": "NA",
        },
      );

      final data = jsonDecode(response.body);
      debugPrint("Response: $data");

      if (data['status'] == true) {
        // ✅ Stop location
        await stopLocationTracking();

        // ✅ Stop background service
        FlutterBackgroundService().invoke('stopService');

        // ✅ Clear only required data
        await prefs.remove('attendance_id');

        if (mounted) {
          setState(() => attendanceId = null);
        }

        debugPrint("✅ Auto punch out success");

        // ✅ Call logout only once
        logout(context);

      } else {
        debugPrint("❌ Punch out failed: ${data['message']}");
      }

    } catch (e) {
      debugPrint("❌ Auto punch out error: $e");
    }
  }

  /* ---------------- STOP TRACKING ---------------- */

  Future<void> stopLocationTracking() async {
    gpsTimer?.cancel();
    gpsTimer = null;

    if (attendanceId == null) return;

    try {
      final internet = await hasRealInternet();

      if (internet) {
        await http.post(
          Uri.parse(
            "http://15.206.209.30/attendance/track_location.php",
          ),
          body: {
            "attendance_id": attendanceId!,
            "status": "stop",
          },
        );

        debugPrint("✅ Tracking stopped on server");
      } else {
        debugPrint("📴 Tracking stop saved locally (offline)");
      }
    } catch (e) {
      debugPrint("⚠ Tracking stop failed but ignored");
    }
  }


  /* ---------------- checkDistanceAndAutoPunchOut ---------------- */
  bool isAutoPunching = false;

  Future<void> checkDistanceAndAutoPunchOut() async {
    if (attendanceId == null || isAutoPunching) return;

    try {
      final pos = currentPosition ?? await getCurrentLocation();

      final double branchLat = double.parse(widget.userModel.branchLat);
      final double branchLng = double.parse(widget.userModel.branchLong);
      final double allowedRadius =
      double.parse(widget.userModel.branchDistance);

      final double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        branchLat,
        branchLng,
      );

      debugPrint(
        "📍 Distance: ${distance.toStringAsFixed(2)}m / Allowed: $allowedRadius",
      );

      /// 🔴 Outside radius (with buffer)
      if (distance > (allowedRadius + 20)) {
        isAutoPunching = true;

        await autoPunchOut("You are outside Kiosk radius");
        // await sendFcmMessageWithOAuth(
        //   widget.userModel.userToken,
        //   "Auto Punch-Out",
        //   "Aap kiosk radius ke bahar the, isliye system ne aapka punch-out automatically kar diya hai.",
        // );
        if (mounted) {
          Get.offAll(() => LoginScreen());
        }
      }

    } catch (e) {
      debugPrint("❌ Distance check error: $e");
    }
  }
  /**/
  Future<void> sendFcmMessageWithOAuth(
      String token,
      String title,
      String body,
      ) async {
    GetServerKey getServerKey = GetServerKey();
    String? serverKey = await getServerKey.getServerKeyToken();
    print("User Token Key: ${token}");
    print("Server Key: ${serverKey}");
    print("Notification Title: ${title}");
    print("Notification Body: ${body}");

    final response = await http.post(
      Uri.parse(
        "https://fcm.googleapis.com/v1/projects/joizone/messages:send",
      ),
      headers: {
        "Authorization": "Bearer $serverKey",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
        },
      }),
    );
    print("FCM Response: ${response.body}");

    if (response.statusCode == 200) {
      await saveNotification(
        cid: widget.userModel.cid.toString() ?? '',
        uid: widget.userModel.uid.toString() ?? '',
        userName: widget.userModel.fullName.toString() ?? '',
        branchName: widget.userModel.branchName.toString() ?? '',
        title: title,
        body: body,
      );
    }

    setState(() {});
  }
  Future<void> saveNotification({
    required String cid,
    required String uid,
    required String userName,
    required String branchName,
    required String title,
    required String body,
  }) async {
    try {
      print("CID : $cid");
      print("UID : $uid");
      print("USER NAME : $userName");
      print("BRANCH : $branchName");
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/save_notification.php",
        ),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "cid": cid,
          "uid": uid,
          "user_name": userName,
          "branch_name": branchName,
          "notification_title": title,
          "notification_body": body,
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
    } catch (e) {
      print("Save Notification Error: $e");
    }
  }
  /**/
  /* ---------------- UI ---------------- */
  bool isOnline = false;
  Timer? _timer;
  int _seconds = 0;
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (breakStartTime != null) {
        final diff = DateTime.now().difference(breakStartTime!);

        setState(() {
          _seconds = diff.inSeconds;
        });
      }
    });
  }


  void _startBreakDialog() {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {

            // Start timer when dialog builds
            _timer?.cancel();
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (breakStartTime != null) {
                final diff = DateTime.now().difference(breakStartTime!);

                setDialogState(() {   // 👈 IMPORTANT
                  _seconds = diff.inSeconds;
                });
              }
            });

            return AlertDialog(
              title: const Text("Break Started"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.watch_later, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {

                    _timer?.cancel();   // 👈 stop timer first

                    try {

                      var response = await endBreakApi(
                        attendanceId: attendanceId!,
                        uid: widget.userModel.uid,
                      );

                      if (response['status'] == true) {

                        Navigator.pop(context);

                        setState(() {
                          isOnline = false;
                          breakStartTime = null;
                          _seconds = 0;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Break Ended\nDuration: ${response['break_minutes']} min",
                            ),
                          ),
                        );

                      }

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("End Break API Error"),
                        ),
                      );
                    }
                  },
                  child: const Text("End Break"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }
  DateTime? breakStartTime;
  Future<bool> checkFeatureAccess() async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/check_feature_access.php"),
      body: {
        "tl_id": widget.userModel.uid.toString(),
        "feature_name": "UpdateUserShiftScreen",
      },
    );

    final json = jsonDecode(response.body);

    return json["enabled"] == 1;
  }
  @override
  Widget build(BuildContext context) {
    final String timeString =
        '${_currentTime.hour.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')}:'
        '${_currentTime.second.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Dashboard",style: TextStyle(color: Colors.white,fontSize: 22,fontFamily: 'impact'),),
        actions: [
          // Stack(
          //   children: [
          //     CircleAvatar(
          //       radius: 20,
          //       backgroundColor: Colors.white,
          //       child: IconButton(
          //         icon: const Icon(
          //           Icons.chat,
          //           color: Colors.blue,
          //         ),
          //         onPressed: () {
          //           Get.to(
          //                 () => ChatbotScreen(
          //               cid: widget.userModel.cid,
          //               uid: widget.userModel.uid,
          //                   name: widget.userModel.fullName,
          //                   branchName: widget.userModel.branchName,
          //             ),
          //           );
          //         },
          //       ),
          //     ),
          //   ],
          // ),
          widget.userModel.departmentName == "Users"?
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.play_circle,color: Colors.blue,),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const VideoDialog(),
                );
              },
            ),
          ):
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(
                Icons.play_circle_outline,
                color: Colors.blue,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const VideoDialogtl(),
                );
              },
            ),
          ),
          SizedBox(width: 5,),
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Get.to(
                          () => NotificationScreen(
                        cid: widget.userModel.cid,
                        uid: widget.userModel.uid,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 5,),
          attendanceId == null
              ? SizedBox.shrink()
              : Row(
            children: [
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged: (value) async {
                  setState(() {
                    isOnline = value;
                  });

                  if (isOnline) {
                    try {
                      var response = await startBreakApi(
                        attendanceId: attendanceId!,
                        uid: widget.userModel.uid,
                      );

                      if (response['status'] == true) {

                        breakStartTime =
                            DateTime.parse(response['break_start_time']);

                        _startTimer();       // ✅ only this timer
                        _startBreakDialog(); // ✅ just open dialog

                      } else {
                        setState(() => isOnline = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['message'])),
                        );
                      }
                    } catch (e) {
                      setState(() => isOnline = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("API Error")),
                      );
                    }
                  }
                },
              )
            ],
          ),
          InkWell(
            onTap: (){
              showDialog(
                context: context,
                builder: (context) => UserIdCardDialog(user: widget.userModel),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: widget.userModel.userImg.isNotEmpty
                  ? ClipOval(
                child: InkWell(
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (context) => UserIdCardDialog(user: widget.userModel),
                    );
                  },
                  child: Image.network(
                    widget.userModel.userImg,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              )
                  : const Icon(
                Icons.person,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(width: 5,),
          attendanceId == null
              ?CircleAvatar(
            radius: 20,
                backgroundColor: Colors.white,
                child: IconButton(

                            icon: const Icon(Icons.logout,color: Colors.blue,),
                            onPressed: () => showLogoutDialog(context),
                          ),
              ): SizedBox.shrink(),

          SizedBox(width: 10,)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            employeeInfoCard(),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controllerTopCenter,
                blastDirectionality: BlastDirectionality.directional,
                blastDirection: pi / 2, // Downward
                emissionFrequency: 0.08,
                numberOfParticles: 55,
                maxBlastForce: 10,
                minBlastForce: 5,
                gravity: 0.4,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: dashboardGrid()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Version : ",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "1.1.1",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.verified_outlined,
                  size: 10,
                  color: Colors.black,
                ),
               
              ],
            ),


            const SizedBox(height: 10),

            // 👇 Postpone Lead Button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      widget.userModel.departmentName == "Team Leader"
          ? Padding(
        padding: const EdgeInsets.only(bottom: 0,right: 10),
        child: FloatingActionButton(
          onPressed: () {
            Get.to(
                  () => UserLiveLocationScreen(
                cid: widget.userModel.cid,
                branch_name: widget.userModel.branchName,
              ),
            );
          },
          backgroundColor: Colors.grey.shade50,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: Colors.blue,
          ),
        ),
      )
          : null,
    );
  }

  /* ---------------- DASHBOARD ---------------- */
  Timer? autoCloseTimer;
  int secondsLeft = 45;

  void startAutoCloseTimer() {
    autoCloseTimer?.cancel();
    secondsLeft = 45;
    late void Function(void Function()) updateDialog;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            updateDialog = setStateDialog; // 🔥 store reference

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Please wait, redirecting shortly 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("You will be redirected in"),
                  const SizedBox(height: 10),

                  /// 🔥 Countdown Text
                  Text(
                    "$secondsLeft sec",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 Progress
                  LinearProgressIndicator(
                    value: secondsLeft / 45,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    /// ✅ TIMER
    autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (secondsLeft <= 0) {
        timer.cancel();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return;
      }
      secondsLeft--;
      /// 🔥 UPDATE UI
      updateDialog(() {});
    });
  }
  IconData getIcon(String iconName) {
    switch (iconName) {
      case "flight":
        return Icons.flight;

      case "business":
        return Icons.business;

      case "person":
        return Icons.person;

      case "feedback":
        return Icons.feedback;

      default:
        return Icons.description;
    }
  }
  Widget dashboardGrid() {

    List<Widget> items = [];
    items.add(
      dashboardBox(
        "Punch In / Out",
        Icons.fingerprint,
            () async {
          final result = await Get.to(
                () => PunchInOutScreen(userModel: widget.userModel),
          );

          if (result == true) {
            startAutoCloseTimer();
          }
        },
      ),
    );

    items.add(
      dashboardBox(
        "My Attendance",
        Icons.event_available,
            () => Get.to(
              () => AttendanceScreen(
            cid: widget.userModel.cid,
            uid: widget.userModel.uid,
          ),
        ),
      ),
    );

    if (attendanceId != null &&
        widget.userModel.departmentName != "Team Leader") {

      widget.userModel.cid==1.toString()?items.add(
        dashboardBox(
          "Client Form",
          Icons.flight,
              () => Get.to(
                () => AirportFormScreen(userModel: widget.userModel),
          ),
        ),
      ):SizedBox.shrink();

      widget.userModel.cid==1.toString()?items.add(
        dashboardBox(
          "Submitted Form",
          Icons.description,
              () => widget.userModel.departmentName == "Users"
              ? Get.to(() => SubmitFormScreen(userModel: widget.userModel))
              : Get.to(() => GetReportKioskScreen(userModel: widget.userModel)),
        ),
      ):SizedBox.shrink();

      widget.userModel.cid==1.toString()?items.add(
        dashboardBox(
          "User Performance",
          Icons.data_exploration,
              () => Get.to(
                () => UsersPerformanceScreen(branchName: widget.userModel.branchName,cid: widget.userModel.cid,),

          ),
        ),
      ):SizedBox.shrink();

      if (forms.isNotEmpty) {
        for (var form in forms) {
          items.add(
            dashboardBox(
              form["form_name"],
              getIcon(form["icon"] ?? "description"),
                  () {
                Get.to(
                      () => DynamicUserFormScreen(
                    templateId: form["id"].toString(),
                    formName: form["form_name"],
                        branchName: widget.userModel.branchName,
                        uid: widget.userModel.uid,
                        cid: widget.userModel.cid,
                  ),
                );
              },
            ),
          );
        }
      }
      items.add(
        dashboardBox(
          "All Submitted Form",
          Icons.event_available,
              () => Get.to(
                () => GetAllDynamicFormScreen(userModel: widget.userModel),
          ),
        ),
      );

    }

    if (widget.userModel.departmentName != "Users") {
      items.add(
        dashboardBox(
          "User Attendance",
          Icons.event_available,
              () => Get.to(
                () => OfficeAttendanceScreen(
              officeName: widget.userModel.branchName,
            ),
          ),
        ),
      );
      widget.userModel.cid==1.toString()?items.add(
        dashboardBox(
          "User Performance",
          Icons.data_exploration,
              () => Get.to(
                () => UsersPerformanceScreen(branchName: widget.userModel.branchName,cid: widget.userModel.cid,),

          ),
        ),
      ):SizedBox.shrink();

      widget.userModel.cid==1.toString()?items.add(
        dashboardBox(
          "Client Submitted Form",
          Icons.event_available,
              () => Get.to(
                () => GetReportKioskScreen(userModel: widget.userModel),
          ),
        ),
      ):SizedBox.shrink();
      //dynamic all form
      items.add(
        dashboardBox(
          "All Submitted Form",
          Icons.event_available,
              () => Get.to(
                () => GetAllDynamicFormScreen(userModel: widget.userModel),
          ),
        ),
      );
      items.add(
        dashboardBox(
          "Update User Shift",
          Icons.access_time,
              () async {
            bool isAllowed = await checkFeatureAccess();

            if (isAllowed) {
              Get.to(
                    () => UpdateUserShiftScreen(
                  cid: widget.userModel.cid,
                  branchName: widget.userModel.branchName,
                ),
              );
            } else {
              Get.defaultDialog(
                title: "Permission Denied",
                middleText:
                "Update User Shift feature is currently disabled by Admin.",
                textConfirm: "OK",
                onConfirm: () => Get.back(),
              );
            }
          },
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: items,
    );
  }

  Widget dashboardBox(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Colors.blue, // 🔥 Border color
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /* ---------------- EMPLOYEE INFO ---------------- */

  Widget employeeInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          border: TableBorder.all(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          children: [
            tableRow("User ID", widget.userModel.userid),
            tableRow("Name", widget.userModel.fullName),
            tableRow("Branch", widget.userModel.branchName),
            tableRow(
              "Shift",
              "${convertTo12Hour(widget.userModel.shiftStart)} - ${convertTo12Hour(widget.userModel.shiftEnd)}",
            ),
          ],
        ),
      ),
    );
  }
  String convertTo12Hour(String? time) {
    if (time == null || time.trim().isEmpty) {
      return "--";
    }

    try {
      DateTime parsedTime = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return "--";
    }
  }

  TableRow tableRow(String title, String? value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value ?? "-",
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

}