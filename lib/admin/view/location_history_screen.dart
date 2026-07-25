import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import '../controller/user_controller.dart';
import '../model/location_history_model.dart';
import '../model/user_model.dart';
import 'package:http/http.dart' as http;

import 'google_map_screen.dart';
import 'location_history_map_screen.dart';


class LocationHistoryScreen extends StatefulWidget {
  final String cid;
  const LocationHistoryScreen({super.key,required this.cid
  });

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final UserController controller = UserController();
  bool isLoading = true;
  List<UserModel> users = [];
  UserModel? selectedUser;

  DateTime? selectedDate;
  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final fetchedUsers = await controller.fetchUsersByCid1(widget.cid);
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }

  /// 📅 Open Date Picker
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
        "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }
  List<AttendanceHistoryModel> historyList = [];
  bool isHistoryLoading = false;

  Future<void> fetchAttendanceHistory() async {
    setState(() {
      isHistoryLoading = true;
      historyList.clear();
    });

    String formattedDate =
    DateFormat('yyyy-MM-dd').format(selectedDate!);

    final response = await http.get(
      Uri.parse(
          "http://15.206.209.30/attendance/location_history.php?uid=${selectedUser!.uid}&date=$formattedDate"),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      List temp = data['data'];

      historyList = (data['data'] as List)
          .map((e) => AttendanceHistoryModel.fromJson(e))
          .toList();
    }

    setState(() {
      isHistoryLoading = false;
    });
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
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Location History",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          ElevatedButton(onPressed: (){
            Get.to(()=>GoogleMapScreen(cid:widget.cid));
          },style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ), child: Text("Active User Map")),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select User",
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// 🔽 User Dropdown
        DropdownSearch<UserModel>(
          selectedItem: selectedUser,
          items: users
              .where((user) => user.status == "active")
              .toList(),
          itemAsString: (UserModel user) =>
          "${user.userid} - ${user.fullName}",

          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: "Search User",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: "Choose User",
              border: OutlineInputBorder(),
            ),
          ),

          onChanged: (UserModel? value) {
            setState(() {
              selectedUser = value;
            });
          },
        ),

            const SizedBox(height: 15),

            /// 📅 Date TextField
            TextFormField(
              controller: dateController,
              readOnly: true,
              onTap: pickDate,
              decoration: const InputDecoration(
                labelText: "Select Date",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month,color: Color(0xff2563EB),),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔘 Track Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedUser == null || selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select user and date")),
                    );
                    return;
                  }

                  String formattedDate =
                  DateFormat('yyyy-MM-dd').format(selectedDate!);
                  fetchAttendanceHistory();
                  debugPrint(
                      "Tracking User: ${selectedUser!.uid} on $formattedDate");
                },
                child: const Text("Track User"),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: isHistoryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : historyList.isEmpty
                  ? const Center(child: Text("No Data Found"))
                  : ListView.builder(
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Name
                              Text(
                                item.fullname,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              IconButton(onPressed: (){
                                print(item.attendanceId);
                                print(item.branchLong.toString());
                                print(item.branchLong.toString());
                                Get.to(()=>LocationHistoryMapScreen(attendance_id:item.attendanceId,branch_lat: item.branchLat.toString(), branch_long: item.branchLong.toString(),));
                              }, icon: Icon(Icons.location_on,color: Colors.red,))
                            ],
                          ),
                          const SizedBox(height: 5),

                          /// Date
                          Text(
                            "Date: ${item.date}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Divider(),

                          /// Punch In Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Punch In",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.punchInTime ?? "-",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// Punch Out Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Punch Out",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.punchOutTime ?? "-",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}