import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:joizone/services/get_server_key.dart';
import 'package:http/http.dart' as http;
import '../controller/user_controller.dart';

class SendNotificationScreen extends StatefulWidget {
  final String cid;
  const SendNotificationScreen({super.key,required this.cid});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final UserController controller = UserController();
  GetServerKey getServerKey=GetServerKey();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> selectedUsers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadUsers();
  }
  void showUserSelectionDialog() {
    List<Map<String, dynamic>> tempSelected =
    List.from(selectedUsers);

    List<Map<String, dynamic>> filteredUsers =
    users.where((user) {
      return (user['user_token']
          ?.toString()
          .trim() ??
          '')
          .isNotEmpty;
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Employees"),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [

                    /// Search
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Search Employee - name, branch, userid",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          filteredUsers = users.where((user) {
                            final name = user['full_name']
                                ?.toString()
                                .toLowerCase() ??
                                '';

                            final empId = user['userid']
                                ?.toString()
                                .toLowerCase() ??
                                '';
                            final empBranch = user['branch_name']
                                ?.toString()
                                .toLowerCase() ??
                                '';

                            return name.contains(
                                value.toLowerCase()) ||
                                empId.contains(
                                    value.toLowerCase())|| empBranch.contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    /// Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempSelected =
                                    List.from(filteredUsers);
                              });
                            },
                            child: const Text(
                                "Select All"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempSelected.clear();
                              });
                            },
                            child: const Text("Clear"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user =
                          filteredUsers[index];

                          return CheckboxListTile(
                            value: tempSelected
                                .contains(user),
                            title: Text(
                              "${user['userid']} - ${user['full_name']}",
                            ),
                            subtitle: Text(
                              "${user['branch_name']}",
                            ),
                            onChanged: (value) {
                              setStateDialog(() {
                                if (value == true) {
                                  tempSelected.add(user);
                                } else {
                                  tempSelected.remove(
                                      user);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedUsers =
                          List.from(tempSelected);
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> loadUsers() async {
    users = await controller.fetchUsersByCid(widget.cid);
    setState(() {});
  }
  /// 🔹 Send the Message Multiple Users
  Future<void> _sendMessage() async {
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select employees"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      debugPrint("=======Notification Title/Body=======");
      debugPrint(title);
      debugPrint(body);
      final totalUsers = selectedUsers.length;

      for (var user in selectedUsers) {
        String token = user['user_token'] ?? '';
        debugPrint("=======User Token=======");
        debugPrint(token);

        if (token.isNotEmpty) {
          bool sent = await sendFcmMessageWithOAuth(
            token,
            title,
            body,
          );

          debugPrint("=======Send Notification Status=======");
          debugPrint(sent.toString());
          print("cid : ${user['cid']} (${user['cid'].runtimeType})");
          print("uid : ${user['uid']} (${user['uid'].runtimeType})");
          print("full_name : ${user['full_name']} (${user['full_name'].runtimeType})");
          print("branch_name : ${user['branch_name']} (${user['branch_name'].runtimeType})");
          if (sent) {
            await saveNotification(
              cid: user['cid'].toString(),
              uid: user['uid'].toString(),
              userName: user['full_name'].toString(),
              branchName: user['branch_name'].toString(),
              title: title,
              body: body,
            );
          }
        }
      }

      titleController.clear();
      bodyController.clear();
      selectedUsers.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Notification sent to $totalUsers users",
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔹 FCM Notification Send Function
  Future<bool> sendFcmMessageWithOAuth(
      String token,
      String title,
      String body,
      ) async {
    String? serverKey = await getServerKey.getServerKeyToken();
    debugPrint("======= Server Key =======");
    debugPrint(serverKey);
    final response = await http.post(
      Uri.parse(
        "https://fcm.googleapis.com/v1/projects/joizone/messages:send",
      ),
      headers: {
        "Authorization": "Bearer $serverKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "message": {
          "token": token,
          "notification": {
            "title": title,
            "body": body,
          },
        },
      }),
    );
    debugPrint("======= FCM Response =======");
    print("FCM Response: ${response.body}");
    print("FCM Response: ${response.statusCode == 200}");
    return response.statusCode == 200;
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff2563EB),
                Color(0xff1D4ED8),
              ],
            ),
          ),
        ),
        backgroundColor: Color(0xff2563EB),
        title: Text("Notification",style: TextStyle(color: Colors.white,fontSize: 18),),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: InkWell(
                onTap: () {
                  showUserSelectionDialog();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedUsers.isEmpty
                        ? "Select Employees"
                        : "${selectedUsers.length} Employee Selected",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Message Title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.title, color: Color(0xff2563EB)),
                ),
              ),
            ),

            // 🔹 Message Body
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Message Body",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.message, color: Color(0xff2563EB)),
                ),
              ),
            ),

            // 🔹 Send Message Button
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _sendMessage,
                child: isLoading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Send Message",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
