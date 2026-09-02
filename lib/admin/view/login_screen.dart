import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/services/notification_service.dart';
import 'package:joizone/user/controller/user_login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../user/view/employee_screen.dart';
import 'admin_home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';


class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'admin';
  final UserController userController=UserController();
  final TextEditingController userIdCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
NotificationService notificationService=NotificationService();
  final TextEditingController userId = TextEditingController();
  final TextEditingController userPassword = TextEditingController();
  bool isLoading = false;
  late GoogleSignIn googleSignIn;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    checkLogin1();
    notificationService.requestNotificationPermission();
  }

  void login() async {
    try {
      if (userId.text.isEmpty || userPassword.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter all fields")),
        );
        return;
      }

      setState(() => isLoading = true);

      final result = await userController.loginUser(
        userid: userId.text.trim(),
        password: userPassword.text.trim(),
      );

      setState(() => isLoading = false);

      if (result['status'] == true) {
        final data = result['data'];

        print("------data--------------------");
        print(data);
        print("-----------------------------");

        UserModel userModel = UserModel(
          uid: data['uid']?.toString() ?? '',
          cid: data['cid']?.toString() ?? '',
          userid: data['userid']?.toString() ?? '',
          password: data['userPassword']?.toString() ?? '',
          userToken: data['user_token']?.toString() ?? '',
          userImg: data['userImg']?.toString() ?? '',
          imeiNo: data['imei_no']?.toString() ?? '',
          fullName: data['userName']?.toString() ?? '',
          userEmail: data['userEmail']?.toString() ?? '',
          userPhone: data['userPhone']?.toString() ?? '',
          gender: data['userGender']?.toString() ?? '',
          fullAddress: data['full_address']?.toString() ?? '',
          branchId: data['storeId']?.toString() ?? '',
          branchName: data['storeName']?.toString() ?? '',
          branchDistance: data['storeDistance']?.toString() ?? '',
          branchLat: data['storeLat']?.toString() ?? '',
          branchLong: data['storeLong']?.toString() ?? '',
          departmentId: data['department_id']?.toString() ?? '',
          departmentName: data['department_name']?.toString() ?? '',
          shiftId: data['shift_id']?.toString() ?? '',
          shiftStart: data['shift_start']?.toString() ?? '',
          shiftEnd: data['shift_end']?.toString() ?? '',
          dateOfJoining: data['date_of_joining']?.toString() ?? '',
          lastworkingdate: data['last_working_date']?.toString() ?? '',
          status: data['status']?.toString() ?? '',
          role: data['role']?.toString() ?? '',
          createdAt: data['createdAt']?.toString() ?? '',
          updatedAt: data['updatedAt']?.toString() ?? '',
          lastName: data['lastName']?.toString() ?? '',
          middleName: data['middleName']?.toString() ?? '',
          cityName: data['cityName']?.toString() ?? '',
          pinCode: data['pinCode']?.toString() ?? '',
          districtName: data['districtName']?.toString() ?? '',
          reportingPosition: data['reportingPosition']?.toString() ?? '',
        );

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('uid', userModel.uid);
        await prefs.setString('branchLat', userModel.branchLat);
        await prefs.setString('branchLong', userModel.branchLong);
        await prefs.setString('role', userModel.role);
        await prefs.setString('userimg', userModel.userImg);
        await prefs.setString(
          'user_model',
          jsonEncode(userModel.toJson()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome ${userModel.userid}"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHomeScreen(
              userModel: userModel,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Login failed"),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);

      print("LOGIN ERROR:");
      print(e);
      print(stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_model');

    if (userString != null) {
      final json = jsonDecode(userString);
      return UserModel.fromJson(json);
    }
    return null;
  }
  Future<bool> isAttendanceActive(String attendanceId) async {
    try {
      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/check_status.php"),
        body: {
          "attendance_id": attendanceId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// Expected response:
        /// { "status": "active" } OR { "status": "closed" }

        return data["attendance_status"] == "active";
      }
    } catch (e) {
      print("Error checking attendance: $e");
    }

    return false;
  }
  Future<void> checkLogin1() async {
    final prefs = await SharedPreferences.getInstance();

    String? attendanceId = prefs.getString('attendance_id');

    /// 🔥 Get cached user
    UserModel? userModel = await getSavedUser();

    print("Attendance ID: $attendanceId");
    print("UserModel: $userModel");

    /// ❌ If no user → stay on login (DO NOTHING)
    if (userModel == null) return;

    /// ✅ If attendance active → Dashboard
    if (attendanceId != null && attendanceId.isNotEmpty) {
      bool isActive = await isAttendanceActive(attendanceId);
      print("---------------");
      print(isActive);
      print("---------------");
      if (!isActive) {
        /// 🔥 REMOVE OLD attendance_id
        await prefs.remove('attendance_id');

        print("❌ Old attendance removed");

        return; // stay on login
      }
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeHomeScreen(userModel: userModel),
        ),
      );
    }

    /// ❌ If attendance not found → stay on login
  }

  // Future<void> checkLogin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   String? uid = prefs.getString('uid');
  //   String? attendanceId =await  prefs.getString('attendance_id');
  //   String? userData =prefs.getString('user_model');
  //
  //   print("UID: $uid");
  //   print("Attendance ID: $attendanceId");
  //   print("UserData: $userData");
  //
  //   /// ✅ CASE 1: VALID LOGIN
  //   if (attendanceId != null &&
  //       attendanceId.isNotEmpty &&
  //       userData != null &&
  //       userData.isNotEmpty) {
  //     try {
  //       Map<String, dynamic> json = jsonDecode(userData);
  //       UserModel userModel = UserModel.fromJson(json);
  //
  //       if (!mounted) return;
  //
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => EmployeeHomeScreen(userModel: userModel),
  //         ),
  //       );
  //       return;
  //
  //     } catch (e) {
  //       print("User model decode error: $e");
  //     }
  //   }
  //
  //   /// ❌ CASE 2: INVALID / LOGOUT → GO TO LOGIN
  //   if (!mounted) return;
  //
  //   return;
  // }



  Future<void> loginAdmin() async {

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/login.php"), // localhost fix
      body: {
        "user_id": userIdCtrl.text,
        "password": passwordCtrl.text,
      },
    );
    print(response);
    final data = json.decode(response.body);
    print(data);
    setState(() => isLoading = false);
    final cid=data['data']['cid'].toString();
    print("-----------cid : $cid");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cid', data['data']['cid'].toString());
    await prefs.setString('role', 'admin');
    if (data['status'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHomeScreen(cid: data['data']['cid'].toString(),)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }
  }
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff2563EB),
              Color(0xff1D4ED8),
              Color(0xffF8FAFC),
              Color(0xffF8FAFC),
            ],
            stops: [0.0, 0.28, 0.28, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                const SizedBox(height: 15),

                /// LOGO
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.verified_user,
                    size: 40,
                    color: Color(0xff2563EB),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Welcome To Track Me",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Login to continue",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 35),

                /// LOGIN CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: "Login As",
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "user",
                            child: Text("User"),
                          ),
                          DropdownMenuItem(
                            value: "admin",
                            child: Text("Admin"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      if (selectedRole == "admin") ...[

                        TextField(
                          controller: userIdCtrl,
                          decoration: InputDecoration(
                            labelText: "Admin User ID",
                            prefixIcon: const Icon(Icons.admin_panel_settings),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: passwordCtrl,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                      ],

                      if (selectedRole == "user") ...[

                        TextField(
                          controller: userId,
                          decoration: InputDecoration(
                            labelText: "User ID",
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: userPassword,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : selectedRole == "admin"
                              ? loginAdmin
                              : login,
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: const Color(0xff2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            "LOGIN",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        "Version 1.0.2",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}