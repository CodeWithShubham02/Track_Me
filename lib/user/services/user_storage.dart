import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {

  static Future<void> saveUser(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('uid', data['uid']?.toString() ?? '');
    await prefs.setString('cid', data['cid']?.toString() ?? '');
    await prefs.setString('userid', data['userid']?.toString() ?? '');

    await prefs.setString(
      'full_name',
      data['full_name']?.toString() ?? '',
    );

    await prefs.setString(
      'user_email',
      data['user_email']?.toString() ?? '',
    );

    await prefs.setString(
      'user_phone',
      data['user_phone']?.toString() ?? '',
    );

    await prefs.setString(
      'branch_id',
      data['branch_id']?.toString() ?? '',
    );

    await prefs.setString(
      'branch_name',
      data['branch_name']?.toString() ?? '',
    );

    await prefs.setString(
      'branch_distance',
      data['branch_distance']?.toString() ?? '',
    );

    await prefs.setString(
      'branch_lat',
      data['branch_lat']?.toString() ?? '',
    );

    await prefs.setString(
      'branch_long',
      data['branch_long']?.toString() ?? '',
    );

    await prefs.setString(
      'department_id',
      data['department_id']?.toString() ?? '',
    );

    await prefs.setString(
      'department_name',
      data['department_name']?.toString() ?? '',
    );

    await prefs.setString(
      'shift_id',
      data['shift_id']?.toString() ?? '',
    );

    await prefs.setString(
      'shift_start',
      data['shift_start']?.toString() ?? '',
    );

    await prefs.setString(
      'shift_end',
      data['shift_end']?.toString() ?? '',
    );

    // Multiple branches
    await prefs.setString(
      'branch_map',
      jsonEncode(data['branch_map'] ?? []),
    );
  }


  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final uid = prefs.getString('uid');

    if (uid == null || uid.isEmpty) {
      return null;
    }

    List<dynamic> branchMap = [];

    final branchMapString = prefs.getString('branch_map');

    if (branchMapString != null &&
        branchMapString.isNotEmpty) {
      try {
        branchMap = jsonDecode(branchMapString);
      } catch (_) {
        branchMap = [];
      }
    }

    return {
      'uid': prefs.getString('uid') ?? '',
      'cid': prefs.getString('cid') ?? '',
      'userid': prefs.getString('userid') ?? '',
      'full_name': prefs.getString('full_name') ?? '',
      'user_email': prefs.getString('user_email') ?? '',
      'user_phone': prefs.getString('user_phone') ?? '',

      'branch_id': prefs.getString('branch_id') ?? '',
      'branch_name': prefs.getString('branch_name') ?? '',
      'branch_distance':
      prefs.getString('branch_distance') ?? '',
      'branch_lat': prefs.getString('branch_lat') ?? '',
      'branch_long': prefs.getString('branch_long') ?? '',

      'department_id':
      prefs.getString('department_id') ?? '',
      'department_name':
      prefs.getString('department_name') ?? '',

      'shift_id': prefs.getString('shift_id') ?? '',
      'shift_start': prefs.getString('shift_start') ?? '',
      'shift_end': prefs.getString('shift_end') ?? '',

      'branch_map': branchMap,
    };
  }
}