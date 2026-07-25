import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SubmittedFormDetailScreen extends StatefulWidget {
  final String submissionId;

  const SubmittedFormDetailScreen({
    super.key,
    required this.submissionId,
  });

  @override
  State<SubmittedFormDetailScreen> createState() =>
      _SubmittedFormDetailScreenState();
}

class _SubmittedFormDetailScreenState
    extends State<SubmittedFormDetailScreen> {
  bool loading = true;
  String error = "";

  Map<String, dynamic>? formData;

  @override
  void initState() {
    super.initState();
    loadDetails();
    print("=========================submissionId==============================");
    print(widget.submissionId);
    print("======================submissionId=================================");
  }

  Future<void> loadDetails() async {
    try {
      setState(() {
        loading = true;
      });

      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_dynamic_form_details.php?submission_id=${widget.submissionId}",
        ),
      );
      print("=======================================================");
      print(response.statusCode);
      print(response.body);
      print("========================================================");

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        formData = Map<String, dynamic>.from(json["data"]);
      } else {
        error = json["message"] ?? "No Data Found";
      }
    } catch (e) {
      error = e.toString();
      print(e);
    }

    setState(() {
      loading = false;
    });
  }

  bool isImage(String value) {
    return value.toLowerCase().endsWith(".png") ||
        value.toLowerCase().endsWith(".jpg") ||
        value.toLowerCase().endsWith(".jpeg") ||
        value.toLowerCase().endsWith(".gif") ||
        value.toLowerCase().contains("/uploads/");
  }

  Widget buildField(Map<String, dynamic> field) {
    String label = field["label"]?.toString() ?? "";
    String value = field["value"]?.toString() ?? "";
    String type = field["type"]?.toString() ?? "";

    if (type == "image" || isImage(value)) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              value.isEmpty
                  ? const Text("No Image")
                  : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  value,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Text("Image not found");
                  },
                ),
              )
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }

  Widget infoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value?.toString() ?? ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submitted Form Details"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : error.isNotEmpty
          ? Center(
        child: Text(error),
      )
          : RefreshIndicator(
        onRefresh: loadDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        formData?["form_name"] ?? "",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formData?["description"] ?? "",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              infoTile(
                "Employee",
                formData?["full_name"],
              ),

              infoTile(
                "Mobile",
                formData?["user_phone"],
              ),

              infoTile(
                "Department",
                formData?["department_name"],
              ),

              infoTile(
                "Branch",
                formData?["branch_name"],
              ),

              infoTile(
                "Submitted At",
                formData?["submitted_at"],
              ),

              const SizedBox(height: 20),

              const Text(
                "Submitted Fields",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(),

              ...(formData?["fields"] as List? ?? [])
                  .map(
                    (e) => buildField(
                  Map<String, dynamic>.from(e),
                ),
              )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}