import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/shift_model.dart';

class ShiftController {
  final String baseUrl = "http://15.206.209.30/attendance";

  Future<List<ShiftModel>> fetchShifts(String cid) async {
    final res = await http.get(
      Uri.parse("$baseUrl/get_shift.php?cid=$cid"),
    );
    final data = json.decode(res.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => ShiftModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<bool> addShift(String cid, String start, String end) async {
    final res = await http.post(
      Uri.parse("$baseUrl/add_shift.php"),
      body: {
        "cid": cid,
        "shift_start": start,
        "shift_end": end,
      },
    );
    final data = json.decode(res.body);
    print("----------");
    print(data);
    print("----------");
    return data['status'] == true;
  }

  Future<bool> updateShift(
      String shiftId, String start, String end) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_shift.php"),
      body: {
        "shift_id": shiftId,
        "shift_start": start,
        "shift_end": end,
      },
    );
    final data = json.decode(res.body);
    return data['status'] == true;
  }

  Future<bool> deleteShift(String shiftId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/delete_shift.php"),
      body: {
        "shift_id": shiftId,
      },
    );
    final data = json.decode(res.body);
    return data['status'] == true;
  }
}
