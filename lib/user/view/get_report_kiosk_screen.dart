import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';

import '../controller/get_report_kiosk_controller.dart';
import '../model/client_form_report_model.dart';

class GetReportKioskScreen extends StatefulWidget {
  UserModel userModel;
   GetReportKioskScreen({super.key, required this.userModel});

  @override
  State<GetReportKioskScreen> createState() => _GetReportKioskScreenState();
}

class _GetReportKioskScreenState extends State<GetReportKioskScreen> {
  DateTime selectedDate = DateTime.now();
  List<ClientFormReportModel> reports = [];
  bool loading = false;

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

    String date =
    DateFormat('yyyy-MM-dd').format(selectedDate);

    reports = await GetReportKioskController.fetchReports(
      widget.userModel.branchName,
      date,
    );
    print("----------report----------");
    print(reports);

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // today data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Client Submitted Form",style: TextStyle(color: Colors.white,fontSize: 16),),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
            border: TableBorder.all(
              color: Colors.grey,
              width: 1,
            ),
            headingRowColor: MaterialStateProperty.all(
              Colors.blue.shade100,
            ),
            columns: const [
              DataColumn(label: Text("User Id")),
              DataColumn(label: Text("User Name")),
              DataColumn(label: Text("User City")),
              DataColumn(label: Text("Kiosk Name")),
              DataColumn(label: Text("Address")),
              DataColumn(label: Text("Snapshot")),
              DataColumn(label: Text("Application No")),
              DataColumn(label: Text("Relation")),
              DataColumn(label: Text("Variant")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Report_Date")),
              DataColumn(label: Text("Report_Time")),
              DataColumn(label: Text("Remark")),
              DataColumn(label: Text("Bank Remark")),
              DataColumn(label: Text("Update Status")),
            ],
            rows: reports.map((r) {
              return DataRow(
                cells: [
                  DataCell(Text(r.userId)),
                  DataCell(Text(r.userName)),
                  DataCell(Text(r.cityName)),
                  DataCell(Text(r.kioskName)),
                  DataCell(Text(r.gpsLocation)),
                  DataCell(
                    r.imageUrls.isNotEmpty
                        ? Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: r.imageUrls.map((url) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: Image.network(url),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              url,
                              height: 50,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
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
                        color: r.status == "APPROVED"
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                  DataCell(Text(r.reportDate)),
                  DataCell(Text(r.reportTime)),
                  DataCell(Text(r.remarks)),
                  DataCell(Text(r.bankRemarks)),
                  DataCell(Text(r.updateStatus)),
                ],
              );
            }).toList(),
          ),
        ),
      ),

    );
  }
}
