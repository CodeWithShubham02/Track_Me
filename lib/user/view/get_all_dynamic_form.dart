import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/user/view/submitted_form_detail_screen.dart';

class GetAllDynamicFormScreen extends StatefulWidget {
  final UserModel userModel;

  const GetAllDynamicFormScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<GetAllDynamicFormScreen> createState() =>
      _GetAllDynamicFormScreenState();
}

class _GetAllDynamicFormScreenState
    extends State<GetAllDynamicFormScreen> {

  bool loading = false;

  DateTime selectedDate = DateTime.now();

  List<dynamic> formList = [];

  @override
  void initState() {
    super.initState();

    fetchForms();
  }

  Future<void> fetchForms() async {

    setState(() {
      loading = true;
    });
    if (widget.userModel.departmentName == "Team Leader") {
      // get_branch_today_forms.php
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/get_branch_today_forms.php",
        ),
        body: {
          "cid": widget.userModel.cid,
          "branch_name": widget.userModel.branchName,
          "date": DateFormat("yyyy-MM-dd").format(selectedDate),
        },
      );
      final json = jsonDecode(response.body);
      print("============================get-dynamic========================");
      print(json);
      print("====================================================");
      if (json["status"] == true) {
        formList = json["data"];
      } else {
        formList = [];
      }

      setState(() {
        loading = false;
      });

    } else {
      // get_user_today_forms.php
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/get_branch_today_forms.php",
        ),
        body: {
          "cid": widget.userModel.cid,
          "branch_name": widget.userModel.branchName,
          "date": DateFormat("yyyy-MM-dd").format(selectedDate),
        },
      );
      final json = jsonDecode(response.body);
      if (json["status"] == true) {
        formList = json["data"];
      } else {
        formList = [];
      }

      setState(() {
        loading = false;
      });

    }




  }

  Future<void> pickDate() async {

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    selectedDate = date;

    fetchForms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "All Submitted Form",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month),
          )
        ],
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : formList.isEmpty
          ? const Center(
        child: Text("No Form Found"),
      )
          : Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade50,
            child: Text(
              "Selected Date : ${DateFormat("dd-MM-yyyy").format(selectedDate)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: formList.length,
              itemBuilder: (context, index) {

                final item = formList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: Colors.blue,
                    ),

                    title: Text(
                      item["form_name"] ?? "",
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          item["full_name"] ?? "",
                        ),

                        Text(
                          item["submitted_at"] ?? "",
                        ),

                      ],
                    ),

                    trailing:IconButton(
                      icon: const Icon(
                        Icons.remove_red_eye,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        print("==================icon click================");
                        print(item["submission_id"].toString());
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmittedFormDetailScreen(
                              submissionId:
                              item["id"].toString(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}