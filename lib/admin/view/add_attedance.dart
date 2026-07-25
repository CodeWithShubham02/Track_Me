import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:intl/intl.dart';

import '../controller/user_controller.dart';
import '../model/user_model.dart';
import 'package:http/http.dart' as http;


class AddAttedance extends StatefulWidget {
  final String cid;
  const AddAttedance({super.key,required this.cid});

  @override
  State<AddAttedance> createState() => _AddAttedanceState();
}

class _AddAttedanceState extends State<AddAttedance> {
  final UserController controller = UserController();

  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? selectedUser;
  String? punchInTime;
  String? punchOutTime;
  String? selectedAttendance;
  String? selectStatus;
  String? selectLate;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    users = await controller.fetchUsersByCid(widget.cid);
    setState(() {});
  }
  Future<String?> pickDateTime(BuildContext context) async {
    DateTime? selectedDate;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)), // Yesterday
      lastDate: DateTime.now(),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    selectedDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      0,
    );

    return DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate);
  }

  final List<String> attendanceOptions = [
    "Present - On Time",
    "Present - Half Day",
    "Present - Late",
    "Present - Early Punch",
  ];
  Future<void> addAttendance(
      Map<String, dynamic> body,
      BuildContext context,
      ) async {

    try {

      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/add_attedance.php"),
        body: body,
      );

      print(response.body);

      final data = jsonDecode(response.body);

      if (data['status'] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
          ),
        );
        Get.back();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
          ),
        );

      }

    } catch (e) {

      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
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
        backgroundColor: Colors.blue,
        title: Text(
          "Attendance Entry",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownSearch<Map<String, dynamic>>(
            items: users,
            selectedItem: selectedUser,
            itemAsString: (user) =>
            "${user['userid']} - ${user['full_name']}",

                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                labelText: "Select Employee",
                border: OutlineInputBorder(),
              ),
            ),
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search employee...",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            onChanged: (value) {
              setState(() {
                selectedUser = value;
              });

              print("UID : ${value?['uid']}");
              print("USER ID : ${value?['userid']}");
              print("FULL NAME : ${value?['full_name']}");
              print("SHIFT START : ${value?['shift_start']}");
              print("SHIFT END : ${value?['shift_end']}");
              print("DEPARTMENT : ${value?['department_name']}");
              print("BRANCH : ${value?['branch_name']}");
              print("BRANCH LAT : ${value?['branch_lat']}");
              print("BRANCH LONG : ${value?['branch_long']}");
              print("BRANCH DISTANCE : ${value?['branch_distance']}");
            },

            compareFn: (item1, item2) => item1['uid'] == item2['uid'],
            ),
                const SizedBox(height: 20),
                Column(
                  children: [

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: punchInTime),
                      decoration: const InputDecoration(
                        labelText: "Punch In Time",
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final value = await pickDateTime(context);

                        if (value != null) {
                          setState(() {
                            punchInTime = value;
                          });

                          print("Punch In : $value");
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: punchOutTime),
                      decoration: const InputDecoration(
                        labelText: "Punch Out Time",
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final value = await pickDateTime(context);

                        if (value != null) {
                          setState(() {
                            punchOutTime = value;
                          });

                          print("Punch Out : $value");
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedAttendance,
                  decoration: const InputDecoration(
                    labelText: "Attendance Status",
                    border: OutlineInputBorder(),
                  ),
                  items: attendanceOptions.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAttendance = value;
                    });

                    if (value != null) {
                      List<String> parts = value.split(" - ");
                      selectStatus=parts[0];
                      selectLate=parts[1];
                      Map<String, String> result = {
                        "status": parts[0], // Present
                        "late": parts[1],   // On Time
                      };

                      print(result);
                      print(selectStatus);
                      print(selectLate);
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () async{
                  if (selectedUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select employee"),
                      ),
                    );
                    return;
                  }

                  if (punchInTime == null || punchOutTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select punch times"),
                      ),
                    );
                    return;
                  }

                  if (selectedAttendance == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select attendance status"),
                      ),
                    );
                    return;
                  }

                  final Map<String, dynamic> body = {
                    "uid": selectedUser?['uid'].toString() ?? "",
                    "cid": widget.cid,
                    "name": selectedUser?['full_name'] ?? "",
                    "department": selectedUser?['department_name'] ?? "",
                    "branch_name": selectedUser?['branch_name'] ?? "",
                    "branch_lat": selectedUser?['branch_lat'].toString() ?? "",
                    "branch_long": selectedUser?['branch_long'].toString() ?? "",
                    "status": selectStatus ?? "",
                    "late": selectLate ?? "",
                    "shift_start": selectedUser?['shift_start'] ?? "",
                    "shift_end": selectedUser?['shift_end'] ?? "",
                    "punch_in_time": punchInTime ?? "",
                    "punch_out_time": punchOutTime ?? "",
                    "punch_in_remark": "Manual Attendance",
                    "punch_out_remark": "Manual Attendance",
                  };
                  print(body);

                  await addAttendance(body, context);
                },style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Perfect square corners
                  ),
                ),child: Text("Add Attendance"))
              ],
            ),
          ),
        ],
      ),
    );
  }
}