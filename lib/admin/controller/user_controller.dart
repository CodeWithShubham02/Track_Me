import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/js.dart';

import '../model/user_model.dart';

class UserController {
  // ✅ Change URL based on platform
  final String baseUrl = "http://15.206.209.30/attendance";
  // Android Emulator → http://10.0.2.2/joizone
  // Real device → http://YOUR_PC_IP/joizone

  Future<Map<String, dynamic>> createUser({
    required String cid,
    required String userid,
    required String password,
    required String userToken,
    required String userImg,
    required String fullName,
    required String middleName,
    required String lastName,
    required String cityName,
    required String districtName,
    required String pinCodeName,
    required String userEmail,
    required String userPhone,
    required String gender,
    required String fullAddress,
    required String branchId,
    required String branchName,
    required String branchDistance,
    required String branchLat,
    required String branchLong,
    required List<String> branchIds,
    required String departmentId,
    required String departmentName,
    required String shiftId,
    required String shiftStart,
    required String shiftEnd,
    required String dateOfJoining,
    required String imeiNo,
  }) async {
    try {
      print("----------------------");
      print(cid);
      print(userid);
      print(password);
      print(userToken);
      print(userImg);
      print(fullName);
      print(middleName);
      print(lastName);
      print(cityName);
      print(districtName);
      print(pinCodeName);
      print(userEmail);
      print(userPhone);
      print(gender);
      print(fullAddress);
      print(branchId);
      print(branchName);
      print(branchDistance);
      print(branchLat);
      print(branchLong);
      print(departmentId);
      print(departmentName);
      print(shiftId);
      print(shiftStart);
      print(shiftEnd);
      print(dateOfJoining);
      print(imeiNo);
      print(cid);
      print("----------------------");
      final response = await http.post(
        Uri.parse("$baseUrl/add_user.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",

        },
        body: {
          "cid": cid,
          "userid": userid,
          "password": password,
          "user_token": userToken,
          "user_img": userImg,
          "full_name": fullName,
          "middle_name": middleName,
          "last_name": lastName,
          "city_name": cityName,
          "district_name": districtName,
          "pin_code": pinCodeName,
          "reporting_position": 'Reporting position $branchName',
          "user_email": userEmail,
          "user_phone": userPhone,
          "gender": gender,
          "full_address": fullAddress,
          "branch_id": branchId,
          "branch_name": branchName,
          "branch_distance": branchDistance,
          "branch_lat": branchLat,
          "branch_long": branchLong,
          "branch_ids": jsonEncode(branchIds),
          "department_id": departmentId,
          "department_name": departmentName,
          "shift_id": shiftId,
          "shift_start": shiftStart,
          "shift_end": shiftEnd,
          "date_of_joining": dateOfJoining,
          "imei_no": imeiNo,
        },
      );

      print("RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        return {
          "status": decoded["status"] ?? false,
          "message": decoded["message"] ?? "Something went wrong"
        };
      } else {
        return {
          "status": false,
          "message": "Server error"
        };
      }
    } catch (e) {
      print("Create User Error: $e");
      return {
        "status": false,
        "message": "Exception occurred"
      };
    }
  }

  Future<List<UserModel>> fetchUsers() async {
    final response = await http.get(
      Uri.parse("$baseUrl/get_users.php"),
    );

    final data = json.decode(response.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    }
    return [];
  }
  Future<List<UserModel>> fetchUsersByCid1(String cid) async {
    final response = await http.get(
      Uri.parse(
        "http://15.206.209.30/attendance/get_users_cid.php?cid=$cid",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        return (data['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
      }
    }

    return [];
  }
  Future<List<Map<String, dynamic>>> fetchUsersByCid(String cid) async {
    final response = await http.get(
      Uri.parse(
        "http://15.206.209.30/attendance/get_users_cid.php?cid=$cid",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }

    return [];
  }


  Future<List<UserModel>> fetchUsersInactive(String cid) async {
    final response = await http.get(
      Uri.parse("$baseUrl/get_all_users.php?cid=$cid"),
    );

    final data = json.decode(response.body);
    debugPrint("---===============================");
    debugPrint("---===============================");
    print(response.body);
    print(data);
    debugPrint("---===============================");
    debugPrint("---===============================");
    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    }

    return [];
  }
  /// Update user - send all fields
  Future<bool> updateUser({
    required String uid,
    required String cid,
    required String userid,
    required String password,
    required String userToken,
    required String userImg,
    required String imeiNo,
    required String fullName,
    required String cityName,
    required String stateName,
    required String pinCode,
    required String userEmail,
    required String userPhone,
    required String gender,
    required String fullAddress,
    required String branchId,
    required String branchName,
    required String branchDistance,
    required String branchLat,
    required String branchLong,
    required String departmentId,
    required String departmentName,
    required String lastWorkingDate,
    required String shiftId,
    required String shiftStart,
    required String shiftEnd,
    required String dateOfJoining,
    required String status,
    required String role,
    required String createdAt,
  }) async {
    print("-----------------------------------last working date----------------------");
    print(lastWorkingDate);
    print("-----------------------------------last working date----------------------");
    final response = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "uid": uid,
        "cid": cid,
        "userid": userid,
        "password": password,
        "user_token": userToken,
        "user_img": userImg,
        "imei_no": imeiNo,
        "full_name": fullName,
        "city_name": cityName,
        "district_name": stateName,
        "pin_code": pinCode,
        "user_email": userEmail,
        "user_phone": userPhone,
        "gender": gender,
        "full_address": fullAddress,
        "branch_id": branchId,
        "branch_name": branchName,
        "branch_distance": branchDistance,
        "branch_lat": branchLat,
        "branch_long": branchLong,
        "department_id": departmentId,
        "department_name": departmentName,
        "shift_id": shiftId,
        "shift_start": shiftStart,
        "shift_end": shiftEnd,
        "date_of_joining": dateOfJoining,
        "last_working_date": lastWorkingDate,
        "status": status,
        "role": role,
        "createdAt": createdAt,
      },
    );
    print("----------------");
    print(response);
    print("------------------");
    final data = json.decode(response.body);
    return data['status'] == true;
  }
  Future<void> callDeleteApi(String uid) async {
    try {
      final url = Uri.parse(
          "http://15.206.209.30/attendance/delete_user.php?uid=$uid");

      final response = await http.get(url);

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );

          fetchUsers(); // 🔄 refresh table
        } else {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Delete failed")),
          );
        }
      }
    } catch (e) {
      print("Delete Error: $e");
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

}
