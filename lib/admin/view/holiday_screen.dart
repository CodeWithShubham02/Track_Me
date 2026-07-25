import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controller/branch_controller.dart';
import '../controller/holiday_controller.dart';
import '../controller/user_controller.dart';
import '../model/branch_model.dart';
import '../model/user_model.dart';

class HolidayScreen extends StatefulWidget {
  final String cid;
  const HolidayScreen({super.key, required this.cid});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  //branch
  final BranchController _controller = BranchController();
  List<BranchModel> branchList = [];
  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedBranchLat;
  String? selectedBranchLong;
  String? selectedBranchDistance;
  bool isLoading = false;

  final UserController controller = UserController();
  bool isUserLoading = true;
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  String? selectedUserId;
  String? selectedUserName;
  String? selectedUserDepart;
  String? selectedUserCid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadBranches();
    loadUsers();
  }

  Future<void> loadUsers() async {
    users = (await controller.fetchUsersByCid(widget.cid)).cast<UserModel>();

    setState(() {
      filteredUsers = users; // Initially all users
      isLoading = false;
    });
  }

  Future<void> loadBranches() async {
    final list = await _controller.getBranches(widget.cid); // cid = 1

    setState(() {
      branchList = list;
      isLoading = false;
    });
  }

  String selectedStatus = 'HOLYDAY';
  DateTime? selectedDate;

  final TextEditingController dateController = TextEditingController();
  final HolidayController holidayController = HolidayController();
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
        title: Text("Add Weekly Off Manually", style: TextStyle(fontSize: 18,color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    hint: const Text("Select Branch"),
                    value: selectedBranchId,
                    items: branchList.map((branch) {
                      return DropdownMenuItem<String>(
                        value: branch.id,
                        child: Text(branch.branchName),
                      );
                    }).toList(),
              onChanged: (value) {
                final branch = branchList.firstWhere(
                      (b) => b.id == value,
                );

                setState(() {
                  selectedBranchId = branch.id;
                  selectedBranchName = branch.branchName;
                  selectedBranchLat = branch.lat;
                  selectedBranchLong = branch.long;
                  selectedBranchDistance = branch.distance;

                  // Branch Wise Filter
                  filteredUsers = users
                      .where((u) => u.branchId == branch.id)
                      .toList();

                  // Reset User Selection
                  selectedUserId = null;
                  selectedUserCid = null;
                  selectedUserName = null;
                  selectedUserDepart = null;
                });
              },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedUserId,
              hint: const Text("Select User"),
              items: filteredUsers.map((user) {
                return DropdownMenuItem<String>(
                  value: user.uid,
                  child: Text(
                    "${user.userid} - (${user.fullName})",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final user = filteredUsers.firstWhere(
                      (u) => u.uid == value,
                );

                setState(() {
                  selectedUserId = user.uid;
                  selectedUserCid = user.cid;
                  selectedUserName = user.fullName;
                  selectedUserDepart = user.departmentName;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: "Select Status",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'HOLYDAY', child: Text("Holiday")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
                print(selectedStatus);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Select Date",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2030),
                );

                if (pickedDate != null) {
                  selectedDate = pickedDate;
                  dateController.text =
                      "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                }
                print(selectedDate);
              },
            ),
          ),
    ElevatedButton(
    onPressed: () async {
    if (selectedUserId == null ||
    selectedBranchName == null ||
    selectedDate == null) {
    Get.snackbar("Error", "Please select all fields");
    return;
    }

    final result = await holidayController.assignHoliday(
    cid: selectedUserCid!,
    uid: selectedUserId!,
    name: selectedUserName!,
    department: selectedUserDepart!,
    officeName: selectedBranchName!,
    status: selectedStatus,
    date: selectedDate!,
    );

    if (result.status) {
    Get.snackbar("Success", result.message);
    dateController.clear();
    } else {
    Get.snackbar("Failed", result.message);
    }
    },
    child: const Text("Save"),
    ),
        ],
      ),
    );
  }
}
