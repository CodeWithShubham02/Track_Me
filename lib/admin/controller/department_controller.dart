import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/department_model.dart';

class DepartmentController {
  final String baseUrl = "http://15.206.209.30/attendance";

  /// GET
  Future<List<DepartmentModel>> fetchDepartments(String cid) async {
    final res = await http.get(
      Uri.parse("$baseUrl/get_departments.php?cid=$cid"),
    );
    final data = json.decode(res.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => DepartmentModel.fromJson(e))
          .toList();
    }
    return [];
  }

  /// ADD
  Future<bool> addDepartment(String cid, String name) async {
    final res = await http.post(
      Uri.parse("$baseUrl/add_department.php"),
      body: {
        "cid": cid,
        "dname": name,
      },
    );
    final data = json.decode(res.body);
    return data['status'] == true;
  }

  /// UPDATE
  Future<bool> updateDepartment(String id, String name) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_department.php"),
      body: {
        "id": id,
        "dname": name,
      },
    );
    final data = json.decode(res.body);
    return data['status'] == true;
  }

  /// DELETE
  Future<bool> deleteDepartment(String id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/delete_department.php"),
      body: {
        "id": id,
      },
    );
    final data = json.decode(res.body);
    return data['status'] == true;
  }
}
