import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

class GetFormFieldwiseScreen extends StatefulWidget {
  final String templateId;
  final String formName;
  final String cid;
  const GetFormFieldwiseScreen({super.key, required this.templateId,required this.cid,required this.formName});

  @override
  State<GetFormFieldwiseScreen> createState() => _GetFormFieldwiseScreenState();
}

class _GetFormFieldwiseScreenState extends State<GetFormFieldwiseScreen> {
  List report = [];
  bool loading = true;
  DateTimeRange? selectedRange;
  List<String> branches = ["All"];
  String selectedBranch = "All";
  Future<void> loadReport({
    required DateTime from,
    required DateTime to,
  }) async {

    loading = true;
    setState(() {});

    String fromDate =
        "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}";

    String toDate =
        "${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse(
        "http://15.206.209.30/attendance/get_form_fieldwise_report.php"
            "?cid=${widget.cid}"
            "&template_id=${widget.templateId}"
            "&from_date=$fromDate"
            "&to_date=$toDate",
      ),
    );

    final json = jsonDecode(response.body);

    if (json["status"] == true) {
      report = json["data"];
      print("======================================");
      print(report);
      print("======================================");
      prepareBranches();
    } else {
      report = [];
    }

    loading = false;
    setState(() {});
  }
  List get filteredReport {

    if (selectedBranch == "All") {
      return report;
    }

    return report.where((e) {
      return e["branch_name"] == selectedBranch;
    }).toList();
  }
  void prepareBranches() {

    Set<String> temp = {"All"};

    for (var item in report) {

      if (item["branch_name"] != null &&
          item["branch_name"].toString().isNotEmpty) {

        temp.add(item["branch_name"]);

      }
    }

    branches = temp.toList();
  }
  Future<void> selectDateRange() async {

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange,
    );

    if (result == null) return;

    selectedRange = result;

    loadReport(
      from: result.start,
      to: result.end,
    );
  }
  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    loadReport(
      from: today,
      to: today,
    );
  }
  List<String> getColumns() {

    Set<String> columns = {};

    for (var item in report) {
      List fields=item["fields"];

      for(var f in fields){
        columns.add(f["field_label"]);
      }

    }

    return columns.toList();
  }
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();
  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }
  Future<void> downloadExcel() async {

    var excel = Excel.createExcel();

    Sheet sheet = excel['Report'];
    for (var sheetName in List.from(excel.tables.keys)) {
      if (sheetName != 'Users_list') {
        excel.delete(sheetName);
      }
    }

    // Header
    List<String> headers = [
      "Employee",
      "Branch",
      "Date",
      ...getColumns(),
    ];

    sheet.appendRow(
      headers.map((e) => TextCellValue(e)).toList(),
    );

    // Data
    for (var item in filteredReport) {

      List<CellValue> row = [

        TextCellValue(item["user_name"] ?? ""),

        TextCellValue(item["branch_name"] ?? ""),

        TextCellValue(item["submitted_at"] ?? ""),

        ...getColumns().map((column) {

          String value = "";

          for (var field in item["fields"]) {
            if (field["field_label"] == column) {
              value = field["value"]?.toString() ?? "";
              break;
            }
          }

          return TextCellValue(value);

        }).toList(),

      ];

      sheet.appendRow(row);
    }

    final bytes = excel.encode();

    if (bytes == null) return;

    final blob = html.Blob([bytes]);

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "${widget.formName}.xlsx",
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

///Add edit form functionality in dynamic form
  void showEditFieldDialog(Map<String,dynamic> item){
    print("selected data");
    List fields=item["fields"];

    Map<String, TextEditingController> controllers = {};

    for(var field in fields){

      controllers[field["field_id"].toString()] = TextEditingController(
        text: field["value"]?.toString() ?? "",
      );

    }

    showDialog(
      context: context,
      builder: (_){

        return AlertDialog(

          title: const Text("Edit Form"),

          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: fields.map<Widget>((field){

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical:8),
                    child: TextField(
                      controller: controllers[field["field_id"]],
                      decoration: InputDecoration(
                        labelText: field["field_label"],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );

                }).toList(),
              ),
            ),
          ),

          actions:[

            TextButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(

              onPressed: () async{

                List<Map<String,dynamic>> data=[];

                for(var field in fields){

                  data.add({

                    "field_id":field["field_id"],

                    "value":controllers[field["field_id"]]!.text,

                  });

                }

                await updateForm(
                  item["submission_id"].toString(),
                  data,
                );

              },

              child: const Text("Update"),

            )

          ],

        );

      },

    );

  }
  Future<void> updateForm(
      String submissionId,
      List<Map<String, dynamic>> data,
      ) async {
    try {
      print("========== Update Request ==========");
      print("Submission ID : $submissionId");
      print("Data : ${jsonEncode(data)}");

      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/update_dynamic_form.php",
        ),
        body: {
          "submission_id": submissionId,
          "form_data": jsonEncode(data),
        },
      );

      print("Status Code : ${response.statusCode}");
      print("Response : ${response.body}");

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Form Updated Successfully"),
          ),
        );

        Navigator.pop(context);

        await loadReport(
          from:selectedRange!.start,
          to:selectedRange!.end,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json["message"] ?? "Update Failed"),
          ),
        );
      }
    } catch (e) {
      print("Update Error : $e");

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
          widget.formName,
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: selectDateRange,
            icon: const Icon(Icons.calendar_month),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: (value) {
              setState(() {
                selectedBranch = value;
              });
            },
            itemBuilder: (context) {
              return branches.map((e) {
                return PopupMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList();
            },
          ),
          IconButton(
            onPressed: downloadExcel,
            icon: const Icon(Icons.save_alt_outlined),
          ),
          SizedBox(width: 50,)
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : report.isEmpty
          ? const Center(child: Text("No Record"))
          : Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) =>
        notification.depth == 0,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: verticalController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: verticalController,
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 48,
                dataRowHeight: 70,
                headingRowColor:
                MaterialStateProperty.all(Colors.grey.shade200),

                columns: [
                  const DataColumn(label: Text("Action",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                  const DataColumn(label: Text("Employee",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                  const DataColumn(label: Text("Branch",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),
                  const DataColumn(label: Text("Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),)),

                  ...getColumns().map(
                        (e) => DataColumn(
                      label: Text(e,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14),),
                    ),
                  ),
                ],

                rows: filteredReport.map<DataRow>((item) {
                  return DataRow(
                      cells: [
                        DataCell(IconButton(onPressed: (){
                              print("Edit Clicked"); // Check console
                              showEditFieldDialog(item);
                            },icon: Icon(Icons.edit,color: Colors.red,))),
                        DataCell(Text(item["user_name"] ?? "")),
                        DataCell(Text(item["branch_name"] ?? "")),
                        DataCell(Text(item["submitted_at"] ?? "")),

                        ...getColumns().map((field) {

                          String value = "";

                          for (var f in item["fields"]) {
                            if (f["field_label"] == field) {
                              value = f["value"]?.toString() ?? "";
                              break;
                            }
                          }

                          // Image URL check
                          if (value.startsWith("http") &&
                              (value.endsWith(".jpg") ||
                                  value.endsWith(".jpeg") ||
                                  value.endsWith(".png") ||
                                  value.endsWith(".webp"))) {

                            return DataCell(
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: InteractiveViewer(
                                        child: Image.network(value),
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  value,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          }

                          // Normal Text
                          return DataCell(
                            Text(value),
                          );

                        }).toList(),
                      ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
