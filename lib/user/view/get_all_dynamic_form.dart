import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/api_urls.dart';
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
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final branchNames = widget.userModel.branchMap
          .map((branch) =>
      branch['branch_name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      final date = DateFormat('yyyy-MM-dd').format(selectedDate);

      debugPrint('ROLE: ${widget.userModel.departmentName}');
      debugPrint('CID: ${widget.userModel.cid}');
      debugPrint('BRANCHES: $branchNames');
      debugPrint('DATE: $date');

      if (branchNames.isEmpty) {
        setState(() {
          formList = [];
        });
        return;
      }

      // Same API request for Team Leader and User
      final response = await http
          .post(
        Uri.parse(ApiUrls.getBranchTodayForm),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cid': widget.userModel.cid.toString(),
          'branch_name': branchNames,
          'date': date,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('API STATUS: ${response.statusCode}');
      debugPrint('API RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['status'] == true) {
        final data = decoded['data'];

        if (!mounted) return;

        setState(() {
          formList = data is List ? List<dynamic>.from(data) : [];
        });
      } else {
        if (!mounted) return;

        setState(() {
          formList = [];
        });

        debugPrint('API message: ${decoded['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch forms error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        formList = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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