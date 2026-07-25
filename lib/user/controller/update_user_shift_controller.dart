import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateUserShiftController {

  Future<bool> updateUserShift({
    required String cid,
    required String uid,
    required String shiftStart,
    required String shiftEnd,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/update_user_shift.php"),
        body: {
          "cid": cid,
          "uid": uid,
          "shift_start": shiftStart,
          "shift_end": shiftEnd,
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        return true;
      } else {
        print(data["message"]);
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}