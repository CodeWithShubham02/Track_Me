import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/user/model/client_form_report_model.dart';
import '../controller/get_form_report_controller.dart';

class SubmitFormScreen extends StatefulWidget {
  final UserModel userModel;
  const SubmitFormScreen({super.key, required this.userModel});

  @override
  State<SubmitFormScreen> createState() => _SubmitFormScreenState();
}

class _SubmitFormScreenState extends State<SubmitFormScreen> {

  DateTime selectedDate = DateTime.now();
  List<ClientFormReportModel> reports = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchData(); // load today's data
  }

  Future<void> pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: selectedDate,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
      fetchData();
    }
  }

  Future<void> fetchData() async {
    setState(() => loading = true);

    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    reports = await SubmitFormController.fetchReports(
      widget.userModel.uid.toString(),
      date,
    );

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        backgroundColor: Colors.blue,
        title: const Text("Submitted Form",style: TextStyle(color: Colors.white,fontSize: 18,fontFamily: 'impact'),),

        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
          )
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text("No records found"))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            border: TableBorder.all(color: Colors.grey),
            headingRowColor: MaterialStateProperty.all(
              Colors.blue.shade100,
            ),
            columns: const [
              DataColumn(label: Text("Images")),
              DataColumn(label: Text("App No")),
              DataColumn(label: Text("Relation")),
              DataColumn(label: Text("Variant")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Bank Remark")),
              DataColumn(label: Text("Update Status")),
              DataColumn(label: Text("Time")),
            ],
            rows: reports.map((r) {
              return DataRow(
                cells: [

                  /// ✅ FIXED HERE
                  DataCell(
                    r.imageUrls.isNotEmpty
                        ? SizedBox(
                      width: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: r.imageUrls.length,
                        itemBuilder: (context, index) {
                          final url = r.imageUrls[index];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.network(url),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                        : const Icon(Icons.image_not_supported),
                  ),

                  DataCell(Text(r.applicationNo)),
                  DataCell(Text(r.relation)),
                  DataCell(Text(r.variant)),

                  DataCell(
                    Text(
                      r.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.status.toUpperCase() == "APPROVED"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                  DataCell(Text(r.bankRemarks)),
                  DataCell(Text(r.updateStatus)),
                  DataCell(Text(r.reportTime)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
