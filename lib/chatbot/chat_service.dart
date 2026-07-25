import 'dart:convert';

import 'package:http/http.dart' as http;


import 'chat_model.dart';

class ChatService {

  static const String baseUrl =
      "http://15.206.209.30/attendance/";

  static Future<List<ChatModel>> getMessages(String cid) async {

    final response = await http.get(
      Uri.parse("${baseUrl}getMessage.php?cid=$cid"),
    );

    final json = jsonDecode(response.body);

    List list = json['data'];

    return list.map((e) => ChatModel.fromJson(e)).toList();
  }

  static Future<bool> sendMessage({
    required String cid,
    required String uid,
    required String username,
    required String branchname,
    required String message,
  }) async {

    final response = await http.post(
      Uri.parse("${baseUrl}sendMessage.php"),
      body: {
        "cid": cid,
        "uid": uid,
        "username": username,
        "branchname": branchname,
        "message": message,
      },
    );

    final json = jsonDecode(response.body);

    return json["status"];
  }
}