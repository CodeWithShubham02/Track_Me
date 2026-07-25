import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joizone/user/controller/update_user_shift_controller.dart';
import 'package:confetti/confetti.dart';
import '../../admin/controller/branch_controller.dart';
import '../../admin/controller/user_controller.dart';
import '../../admin/model/branch_model.dart';
import '../../admin/model/user_model.dart';

class UpdateUserShiftScreen extends StatefulWidget {
  final String cid;
  final String branchName;
  const UpdateUserShiftScreen({super.key,required this.cid,required this.branchName});

  @override
  State<UpdateUserShiftScreen> createState() => _UpdateUserShiftScreenState();
}

class _UpdateUserShiftScreenState extends State<UpdateUserShiftScreen> {


  final UserController controller = UserController();
  final UpdateUserShiftController updateUserShiftController=UpdateUserShiftController();
  bool isUserLoading = true;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    loadUsers();
  }


  List<UserModel> users = [];

  Future<void> loadUsers() async {
    final allUsers = await controller.fetchUsersByCid1(widget.cid);

    users = allUsers.where((user) {
      return user.branchName.trim().toLowerCase() ==
          widget.branchName.trim().toLowerCase() && user.departmentName.trim() == "Users";
    }).toList();

    setState(() {
      isUserLoading = false;
    });
  }
  String convertTo12Hour(String? time) {
    if (time == null || time.isEmpty) return "--";

    try {
      final parsedTime = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(
            color: Colors.white
        ),
        title: const Text("Update Users Shift",style: TextStyle(color: Colors.white,fontSize: 18),),

      ),
      body: Column(
        children: [
          //TOP CENTER - shoot down

          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: Text(
                "Branch : ${widget.branchName}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20,),

          Expanded(
            child: isUserLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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

                        Text(
                          "Shift : ${convertTo12Hour(emp.shiftStart)} - ${convertTo12Hour(emp.shiftEnd)}",
                        ),
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
          const SizedBox(height: 20,),

        ],
      ),
    );
  }
  String convertTo24Hour(String time) {
    try {
      final inputFormat = DateFormat("hh:mm a");
      final outputFormat = DateFormat("HH:mm:ss");

      final date = inputFormat.parse(time);
      return outputFormat.format(date);
    } catch (e) {
      return time;
    }
  }
  Widget editDialog(UserModel emp) {
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
          onPressed: () async {

            final shiftStart = convertTo24Hour(start);
            final shiftEnd = convertTo24Hour(end);

            bool success = await updateUserShiftController.updateUserShift(
              cid: widget.cid,
              uid: emp.uid,
              shiftStart: shiftStart,
              shiftEnd: shiftEnd,
            );

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Shift Updated Successfully"),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pop(context);

              loadUsers(); // Refresh List
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Failed to Update Shift"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
