import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/roster/roster_service.dart';

import '../controller/branch_controller.dart';
import '../controller/user_controller.dart';
import '../model/branch_model.dart';
import '../model/user_model.dart';

class RosterScreen extends StatefulWidget {
  final String cid;

  const RosterScreen({
    super.key,
    required this.cid,
  });

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final TextEditingController searchController = TextEditingController();

  //String selectedOffice = "BOMT2-LG";

  final UserController controller = UserController();
  bool isUserLoading = true;
  List<UserModel> users = [];
  String? selectedUserId;
  String? selectedUserName;
  String? selectedUserDepart;
  String? selectedUserCid;


  final BranchController branch = BranchController();

  List<BranchModel> branches = [];
  BranchModel? selectedOffice;
  bool isLoading = true;

  DateTime selectedDate = DateTime.now();
  String selectedWeek = "";
  late TextEditingController weekController;
  @override
  void initState() {
    super.initState();
    weekController = TextEditingController();
    loadBranches();
    updateWeek(selectedDate);
    print("=====================select week==============");
    print(weekController.text);
  }
  Future<void> loadBranches() async {
    branches = await branch.getBranches(widget.cid);
    if (branches.isNotEmpty) {
      selectedOffice = branches.first;
    }
    setState(() {
      isLoading = false;
    });
  }
  void updateWeek(DateTime date) {
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    DateTime sunday = monday.add(const Duration(days: 6));

    selectedWeek =
    "${monday.day}/${monday.month}/${monday.year} - "
        "${sunday.day}/${sunday.month}/${sunday.year}";

    weekController.text = selectedWeek;

    print("Selected Date : $date");
    print("Week : $selectedWeek");

    setState(() {});
  }
  Future<void> pickWeek() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      print("Picked Date: $picked");

      selectedDate = picked;
      updateWeek(picked);
    }
  }
  Future<void> loadUsers() async {
    final allUsers = await controller.fetchUsersByCid1(widget.cid);

    if (selectedOffice != null) {
      users = allUsers.where((user) {
        return user.branchName.trim().toLowerCase() ==
            selectedOffice!.branchName.trim().toLowerCase();
      }).toList();
    } else {
      users = allUsers;
    }

    setState(() {
      isUserLoading = false;
    });
  }


  List<Map<String, dynamic>> get weekList => List.generate(7, (index) {
    DateTime monday =
    selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    DateTime day = monday.add(Duration(days: index));

    return {
      "day": [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ][index],
      "date": day,
      "display":
      "${[
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ][index]} (${day.day}/${day.month}/${day.year})"
    };
  });

  List<Map<String, dynamic>> rosterData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

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
        iconTheme: IconThemeData(
            color: Colors.white
        ),
        title: const Text("Weekly Schedule",style: TextStyle(color: Colors.white,fontSize: 18),),

      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor:  Color(0xff1D4ED8),
        icon: const Icon(Icons.cloud_upload,color: Colors.white ,),

        label: const Text("Upload Work Schedule",style: TextStyle(color: Colors.white),),
        onPressed: () async {

          if (rosterData.isEmpty) {

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please save at least one employee."),
              ),
            );

            return;
          }

          print(rosterData);

          final result =
          await RosterService.uploadRoster(rosterData);

          if (result["status"] == true) {

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(
                content: Text(result["message"]),
              ),

            );

            rosterData.clear();

          } else {

            ScaffoldMessenger.of(context).showSnackBar(

              SnackBar(
                content: Text(result["message"]),
              ),

            );

          }

        },
      ),

      body: Column(
        children: [

          /// Top Card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<BranchModel>(
                    value: selectedOffice,
                    decoration: const InputDecoration(
                      labelText: "Office",
                      border: OutlineInputBorder(),
                    ),
                    items: branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch,
                        child: Text(branch.branchName),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() {
                        selectedOffice = value;
                        isUserLoading = true;
                      });

                      await loadUsers();
                    },
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: weekController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Select Week",
                      suffixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                    onTap: pickWeek,
                  ),

                  const SizedBox(height: 15),

                  // TextField(
                  //   controller: searchController,
                  //   decoration: InputDecoration(
                  //     hintText: "Search Employee",
                  //     prefixIcon: const Icon(Icons.search),
                  //     filled: true,
                  //     fillColor: Colors.grey.shade200,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),

          /// Employee List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final emp = users[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xff1D4ED8),
                      child: Text(
                        emp.userid.isNotEmpty
                            ? emp.userid[0].toUpperCase()
                            : "?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    title: Text(
                      emp.userid,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),

                        Text("Name : ${emp.fullName}",style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xff1D4ED8)),),

                        Text("Department : ${emp.departmentName}"),

                        Text("Office : ${emp.branchName}"),
                      ],
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.edit,color:  Color(0xff1D4ED8),),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => editDialog(emp),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 70,)
        ],
      ),
    );
  }

  Widget editDialog(UserModel emp) {
    String selectedWeekly = weekList.first["day"];
    String shift = "Morning1";
    String weekly = "Sunday";

    String start = "06:00 AM";
    String end = "02:00 PM";

    return AlertDialog(
      title: Row(
        children: [
          Text(emp.userid,style: TextStyle(fontSize: 22,color:  Colors.red,fontWeight: FontWeight.bold),),
          Text(" - "),
          Text(emp.fullName,style: TextStyle(fontSize: 18,color:  Color(0xff1D4ED8),fontWeight: FontWeight.bold),),
        ],
      ),

      content: StatefulBuilder(
        builder: (context, setStateDialog) {

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              DropdownButtonFormField<String>(
                value: shift,
                decoration: const InputDecoration(
                  labelText: "Shift",
                ),
                items: const [
                  DropdownMenuItem(value: "Morning1", child: Text("Morning1 (06:00 AM - 02:00 PM)")),
                  DropdownMenuItem(value: "Morning2", child: Text("Morning2 (05:00 AM - 01:00 PM)")),
                  DropdownMenuItem(value: "Morning3", child: Text("Morning3 (07:00 AM - 03:00 PM)")),
                  DropdownMenuItem(value: "Evening1", child: Text("Evening1 (03:00 PM - 11:00 PM)")),
                  DropdownMenuItem(value: "Evening2", child: Text("Evening2 (02:00 PM - 10:00 PM)")),
                  DropdownMenuItem(value: "Night", child: Text("Night (11:00 PM - 07:00 AM)")),
                ],
                onChanged: (value) {
                  setStateDialog(() {
                    shift = value!;

                    if (shift == "Morning1") {
                      start = "06:00 AM";
                      end = "02:00 PM";
                    }else if (shift == "Morning2") {
                      start = "05:00 AM";
                      end = "01:00 PM";
                    }else if (shift == "Morning3") {
                      start = "07:00 AM";
                      end = "03:00 PM";
                    }
                    else if (shift == "Evening1") {
                      start = "03:00 PM";
                      end = "11:00 PM";
                    }
                    else if (shift == "Evening2") {
                      start = "02:00 PM";
                      end = "10:00 PM";
                    } else {
                      start = "11:00 PM";
                      end = "07:00 AM";
                    }
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedWeekly,
                decoration: const InputDecoration(
                  labelText: "Weekly Off",
                ),
                items: weekList.map((e) {
                  return DropdownMenuItem<String>(
                    value: e["day"],
                    child: Text(e["display"]),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    selectedWeekly = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              Text(
                "$start - $end",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
        onPressed: () {

    final selectedDay =
    weekList.firstWhere((e) => e["day"] == selectedWeekly);

    DateTime rosterDate = selectedDay["date"];

    print("====================");
    print(widget.cid);
    print(emp.uid);
    print(emp.userid);
    print(emp.departmentName);
    print(emp.branchName);

    print("Status : WO");
    print("Weekly Off : ${selectedDay["day"]}");
    print("Roster Date : $rosterDate");
    print("Shift Start : $start");
    print("Shift End : $end");

    rosterData.add({
    "cid": widget.cid,
    "uid": emp.uid,
      "userid":emp.userid,
    "user_type": emp.departmentName,
    "office_name": emp.branchName,
    "status": "WO",
    "roster_date":  DateFormat('yyyy-MM-dd').format(rosterDate),
    "shift_start": start,
    "shift_end": end,
    });

    Navigator.pop(context);
    },
    child: const Text("Save"),
    ),
      ],
    );
  }
}