import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/branch_model.dart';

class BranchController {
  final String baseUrl = "http://15.206.209.30/attendance";

  /// GET BRANCH LIST
  Future<List<BranchModel>> getBranches(String cid) async {
    final response = await http.get(
      Uri.parse("$baseUrl/branch_list.php?cid=$cid"),
    );

    final data = json.decode(response.body);
    List<BranchModel> list = [];

    if (data['status'] == true) {
      for (var item in data['branches']) {
        list.add(BranchModel.fromJson(item));
      }
    }
    return list;
  }

  /// ADD BRANCH
  Future<bool> addBranch({
    required String branchName,
    required String distance,
    required String cid,
    required String lat,
    required String long,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/branch_create.php"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "branch_name": branchName,
        "distance": distance,
        "cid": cid,
        "branch_lat": lat,
        "branch_long": long,
      },
    );

    final data = json.decode(response.body);
    return data['status'] == true;
  }
  /// UPDATE
  Future<bool> updateBranch(Map<String, String> body) async {
    print(body);
    final res = await http.post(
      Uri.parse("$baseUrl/branch_update.php"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );
    print("==========");
    print(res);
    print(res.statusCode);
    print(res.body);
    print("==========");
    return json.decode(res.body)['status'] == true;
  }

  /// DELETE
  Future<bool> deleteBranch(String id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/branch_delete.php"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"id": id},
    );
    return json.decode(res.body)['status'] == true;
  }
}
