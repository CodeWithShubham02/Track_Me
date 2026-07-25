import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  final String cid;
  final String uid;

  const NotificationScreen({
    super.key,
    required this.cid,
    required this.uid,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  Map<String, dynamic> groupedNotifications = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_notification.php?cid=${widget.cid}&uid=${widget.uid}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        setState(() {
          groupedNotifications = data['data'];
          loading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
    }
  }
  Future<void> markNotificationSeen(String id) async {
    try {
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/update_notification_status.php",
        ),
        body: {
          "id": id,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        fetchNotifications(); // refresh list
      }
    } catch (e) {
      print("Mark Seen Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:  AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      iconTheme:
      const IconThemeData(color: Colors.white),
      title: const Text(
        "Notifications",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : groupedNotifications.isEmpty
          ? const Center(
        child: Text("No Notifications"),
      )
          : ListView.builder(
        itemCount:
        groupedNotifications.keys.length,
        itemBuilder: (context, index) {

          String date =
          groupedNotifications.keys.elementAt(
              index);

          List notifications =
          groupedNotifications[date];

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

          ...notifications.map(
          (item) => InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {

          if (item['status'] == 'unseen') {
          await markNotificationSeen(
          item['id'].toString(),
          );

          setState(() {
          item['status'] = 'seen';
          });
          }

          showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
          ),
          ),
          builder: (_) {
          return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

          Text(
          item['notification_title'],
          style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          ),
          ),

          const SizedBox(height: 15),

          Text(
          item['notification_body'],
          style: const TextStyle(
          fontSize: 16,
          ),
          ),

          const SizedBox(height: 15),

          Text(
          item['createdAt'],
          style: const TextStyle(
          color: Colors.grey,
          ),
          ),
          ],
          ),
          );
          },
          );
          },
          child: Container(
          margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
          ),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
          color: item['status'] == 'unseen'
          ? Colors.green.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
          color: item['status'] == 'unseen'
          ? Colors.green
              : Colors.grey.shade300,
          width:
          item['status'] == 'unseen'
          ? 2
              : 1,
          ),
          boxShadow: [
          BoxShadow(
          color: Colors.black12,
          blurRadius: 3,
          offset: Offset(0, 2),
          )
          ],
          ),
          child: Row(
          children: [

          CircleAvatar(
          radius: 24,
          backgroundColor:
          item['status'] == 'unseen'
          ? Colors.green
              : Colors.grey,
          child: const Icon(
          Icons.notifications,
          color: Colors.white,
          ),
          ),

          const SizedBox(width: 12),

          Expanded(
          child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

          Row(
          children: [

          Expanded(
          child: Text(
          item['notification_title'],
          style: TextStyle(
          fontSize: 16,
          fontWeight:
          item['status'] ==
          'unseen'
          ? FontWeight.bold
              : FontWeight.w500,
          ),
          ),
          ),

          if (item['status'] ==
          'unseen')
          Container(
          padding:
          const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
          ),
          decoration: BoxDecoration(
          color: Colors.green,
          borderRadius:
          BorderRadius.circular(
          20),
          ),
          child: const Text(
          "NEW",
          style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
          FontWeight.bold,
          ),
          ),
          ),
          ],
          ),

          const SizedBox(height: 6),

          Text(
          item['notification_body'],
          maxLines: 2,
          overflow:
          TextOverflow.ellipsis,
          style: TextStyle(
          color: Colors.grey[700],
          ),
          ),

          const SizedBox(height: 8),

          Text(
          item['createdAt'],
          style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
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
            ],
          );
        },
      ),
    );
  }
}