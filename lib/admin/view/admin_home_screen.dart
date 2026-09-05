import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/roster/roster_screen.dart';
import 'package:joizone/admin/view/add_user_screen.dart';
import 'package:joizone/admin/view/create_form_screen.dart';
import 'package:joizone/admin/view/settings_screen.dart';
import 'package:joizone/admin/view/shift_screen.dart';
import 'package:joizone/admin/view/user_attendance_detail_screen.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../chatbot/chatbot_screen.dart';
import '../controller/attendance_location_controller.dart';
import '../controller/user_controller.dart';
import '../model/user_model.dart';
import '../notification/send_notification_screen.dart';
import 'all_branch_screen.dart';
import 'all_employee_attandance.dart';
import 'all_employee_list.dart';
import 'all_form_report_screen.dart';
import 'assign_holiday_screen.dart';
import 'attendance_location_screen.dart';
import 'branch_screen.dart';
import 'department_screen.dart';
import 'google_map_screen.dart';
import 'holiday_screen.dart';
import 'location_history_screen.dart';
import 'login_screen.dart';
import 'monthly_attendance_screen.dart';
import 'monthly_summary_screen.dart';
import 'upload_remark_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String cid;
  const AdminHomeScreen({super.key, required this.cid});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }
  final UserController controller = UserController();
  bool isLoading = true;
  List<UserModel> users = [];
  UserModel? selectedUser; // 🔹 selected user

  @override
  void initState() {
    super.initState();
    loadUsers();
    fetchAttendance();
    fetchUsers();
    fetchTodayReport();
    fetchDynamicFormChart();
    fetchDynamicMonthlyReport(
      DateFormat("yyyy-MM").format(selectedMonth),
    );
    fetchMonthlyReport(
      DateFormat('yyyy-MM').format(DateTime.now()),
    );
    fetchPerformance();
  }
  Future<void> loadUsers() async {

    final fetchedUsers = await controller.fetchUsersByCid1(widget.cid);
    setState(() {
      users = fetchedUsers;
      print("===============================");
      print("===============================");
      print(users);
      print(fetchedUsers);
      print("===============================");
      print("===============================");
      isLoading = false;
    });
  }
  //---chart
  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  int maleCount = 0;
  int femaleCount = 0;

  int reportFilled = 0;
  int reportNotFilled = 0;
  List reportList = [];
  DateTime selectedDate = DateTime.now();

  int presentCount = 0;
  int absentCount = 0;
  int holidayCount = 0;
  Future<void> fetchAttendance({DateTime? date}) async {
    try {
      final DateTime attendanceDate = date ?? selectedDate;

      final String formattedDate = formatDate(attendanceDate);

      debugPrint("Fetching attendance for: $formattedDate");

      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/attedance_chart.php",
        ),
        body: {
          "cid": widget.cid,
          "date": formattedDate,
        },
      );

      debugPrint("Attendance Response: ${response.body}");

      final jsonData = jsonDecode(response.body);

      int present = 0;
      int absent = 0;
      int holiday = 0;

      if (jsonData['status'] == true &&
          jsonData['data'] != null &&
          jsonData['data'] is List) {

        for (var item in jsonData['data']) {
          final String status =
              item['attendance_status']
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
                  "";

          debugPrint("User Status: $status");

          if (status == "PRESENT") {
            present++;
          } else if (status == "HOLYDAY") {
            holiday++;
          } else if (status == "ABSENT") {
            absent++;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        selectedDate = attendanceDate;

        presentCount = present;
        absentCount = absent;
        holidayCount = holiday;
      });

    } catch (e) {
      debugPrint("Attendance Error: $e");
    }
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse("http://15.206.209.30/attendance/get_users_cid.php?cid=${widget.cid}"),
    );
    final data = jsonDecode(response.body);
    int male = 0;
    int female = 0;
    print("=============================");
    print("=============================");
    print(data);
    print(response.body);
    print("=============================");
    print("=============================");
    for (var user in data['data']) {
      if ((user['gender'] ?? "").toString().toLowerCase() == "male") {
        male++;
      } else if ((user['gender'] ?? "").toString().toLowerCase() == "female") {
        female++;
      }
    }

    setState(() {
      maleCount = male;
      femaleCount = female;
    });
  }


  Future<void> fetchTodayReport() async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/get_report.php"),
      body: {
        "cid": widget.cid,
        "date": formatDate(DateTime.now()),
      },
    );

    final data = jsonDecode(response.body);

    int filled = 0;
    int notFilled = 0;
    List tempList = [];

    if (data['data'] != null) {
      for (var item in data['data']) {

        // 👉 full list store karo
        tempList.add(item);

        // 👉 existing logic (optional)
        if (item['duplicate_from'] == "yes" || item['duplicate_from'] == "no") {
          filled++;
        } else {
          notFilled++;
        }
      }
    }

    setState(() {
      reportFilled = filled;
      reportNotFilled = notFilled;

      // 🔥 THIS IS IMPORTANT
      reportList = tempList;
    });
  }

  Widget attendanceChart() {
    int total = presentCount + absentCount + holidayCount;

    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 Text(
                  "📊 Today's Attendance ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 40,),
                IconButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      await fetchAttendance(
                        date: pickedDate,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.calendar_month,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: (presentCount + absentCount + holidayCount) == 0
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: [

                    // PRESENT
                    if (presentCount > 0)
                      PieChartSectionData(
                        value: presentCount.toDouble(),
                        color: Colors.green,
                        title: "$presentCount",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 70,
                      ),

                    // ABSENT
                    if (absentCount > 0)
                      PieChartSectionData(
                        value: absentCount.toDouble(),
                        color: Colors.red,
                        title: "$absentCount",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 70,
                      ),

                    // HOLIDAY
                    if (holidayCount > 0)
                      PieChartSectionData(
                        value: holidayCount.toDouble(),
                        color: Colors.orange,
                        title: "$holidayCount",
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 70,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                Text(
                  "🟢 Present: $presentCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "🔴 Absent: $absentCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "🟠 WO: $holidayCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "👥 Total Employees : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userChart() {
    int total = maleCount + femaleCount;

    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "👥 Total Employees ",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 160,
              child: total == 0
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: maleCount.toDouble(),
                      color: Colors.blue,
                      radius: 70,
                      title:
                      "${((maleCount / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: femaleCount.toDouble(),
                      color: Colors.pink,
                      radius: 70,
                      title:
                      "${((femaleCount / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Male\n$maleCount",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Female\n$femaleCount",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              "👥 Total Employees : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Map<String, int> getKioskCounts(List reports) {
    Map<String, int> kioskCount = {};

    for (var item in reports) {
      String kiosk = item['kiosk_name'] ?? 'Unknown';

      if (kioskCount.containsKey(kiosk)) {
        kioskCount[kiosk] = kioskCount[kiosk]! + 1;
      } else {
        kioskCount[kiosk] = 1;
      }
    }

    return kioskCount;
  }

  List<PieChartSectionData> getSections(
      Map<String, int> kioskData,
      int total,
      ) {
    return kioskData.entries.map((entry) {
      return PieChartSectionData(
        color: getKioskColor(entry.key),
        value: entry.value.toDouble(),
        radius: 70,
        title:
        "${((entry.value / total) * 100).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }
  Color getKioskColor(String kiosk) {
    switch (kiosk.toUpperCase()) {
      case "AMDT1-LB":
        return Colors.blue;
      case "LKOT1-LG":
        return Colors.orange;
      case "BOMT2-LG":
        return Colors.purple;
      case "JAIT1-LG":
        return Colors.green;
      case "Mumbai":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
  Widget reportChart(List reports) {
    final kioskData = getKioskCounts(reports);
    final total = kioskData.values.fold(0, (sum, val) => sum + val);

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "📈 Branch Wise Client Form",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: total == 0
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: getSections(kioskData, total),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: kioskData.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: getKioskColor(entry.key),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${entry.key} (${entry.value})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Text(
              "Total Client Form : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  DateTime selectedMonth = DateTime.now();

  List<Map<String, dynamic>> kioskData = [];
  int totalMonthReports = 0;
  Future<void> fetchMonthlyReport(String month) async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/get_monthly_kiosk_report.php"),
      body: {
        "month": month,
        "cid":widget.cid
      },
    );

    final json = jsonDecode(response.body);

    if (json["status"] == true) {
      setState(() {
        kioskData = List<Map<String, dynamic>>.from(json["data"]);
        totalMonthReports = json["total_reports"];
      });
    }
  }
  List<PieChartSectionData> getMonthlySections() {
    return kioskData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return PieChartSectionData(
        value: (item["total"] as num).toDouble(),
        title: item["total"].toString(),
        radius: 70,
        color: Colors.primaries[index % Colors.primaries.length],
      );
    }).toList();
  }
  Widget reportMonthChart() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "📈 Monthly Client Form ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.calendar_month,color: Colors.redAccent,),
                  onPressed: () async {
                    final month = await showMonthPicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );

                    if (month != null) {
                      selectedMonth = month;

                      await fetchMonthlyReport(
                        DateFormat('yyyy-MM').format(month),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: kioskData.isEmpty
                  ? const Center(child: Text("No Data"))
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: getMonthlySections(),

                ),
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: kioskData.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Container(
                    //   width: 14,
                    //   height: 14,
                    //   color: getKioskColor(item["kiosk_name"]),
                    // ),
                    const SizedBox(width: 5),
                    Text(
                      "${item["kiosk_name"]} (${item["total"]})",
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Text(
              "Total Client Form : $totalMonthReports",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  //--------------get chart dynamic form-------------------
  int totalSubmission = 0;
  List<dynamic> dynamicFormChart = [];
  Future<void> fetchDynamicFormChart() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_dynamic_form_chart.php?cid=${widget.cid}",
        ),
      );

      print(response.statusCode);
      print(response.body);

      final data = jsonDecode(response.body);

      List<dynamic> tempList = [];
      int total = 0;

      if (data["status"] == true && data["data"] != null) {
        for (var item in data["data"]) {
          tempList.add(item);
          total += int.tryParse(item["total"].toString()) ?? 0;
        }
      }

      setState(() {
        dynamicFormChart = tempList;
        totalSubmission = total;
      });

      print(dynamicFormChart);
    } catch (e) {
      print("Dynamic Form Error : $e");
    }
  }
  Color getFormColor(String form) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
    ];

    int index = form.hashCode.abs() % colors.length;

    return colors[index];
  }
  Map<String, int> getDynamicFormCounts(List dynamicFormChart) {
    Map<String, int> data = {};

    for (var item in dynamicFormChart) {
      String formName = item["form_name"] ?? "Unknown";

      int total = int.tryParse(item["total"].toString()) ?? 0;

      data[formName] = total;
    }

    return data;
  }
  List<PieChartSectionData> getDynamicSections(
      Map<String, int> data, int total) {
    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: getFormColor(entry.key),
        value: entry.value.toDouble(),
        radius: 60,
        title: "${percentage.toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }
  Widget dynamicTodayFormChart(List dynamicFormChart) {
    final formData = getDynamicFormCounts(dynamicFormChart);
    final total = formData.values.fold(0, (a, b) => a + b);

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "📝 Dynamic Form Submission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sectionsSpace: 0,
                      sections: total == 0
                          ? [
                        PieChartSectionData(
                          value: 100,
                          color: Colors.grey.shade300,
                          title: "",
                          radius: 60,
                        ),
                      ]
                          : getDynamicSections(formData, total),
                    ),
                  ),
                  if (total == 0)
                    const Text(
                      "No Data",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: formData.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: getFormColor(entry.key),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${entry.key} (${entry.value})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Text(
              "Total Submissions : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  //---------------------------------------------------
  //---------------get monthly wise dynamic data ------------------
  List<Map<String, dynamic>> monthlyDynamicFormData = [];
  int totalMonthlyDynamicForm = 0;

  Future<void> fetchDynamicMonthlyReport(String month) async {
    try {
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/get_monthly_dynamic_form_chart.php",
        ),
        body: {
          "cid": widget.cid,
          "month": month,
        },
      );

      print(response.body);

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        setState(() {
          monthlyDynamicFormData =
          List<Map<String, dynamic>>.from(json["data"]);

          totalMonthlyDynamicForm =
          json["total_submissions"];
        });
      }
    } catch (e) {
      print("Monthly Dynamic Form Error : $e");
    }
  }
  Widget dynamicMonthChart() {

    final formData = getDynamicFormCounts(monthlyDynamicFormData);

    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                const Text(
                  "📅 Monthly Dynamic Form",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.calendar_month,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {

                    final month = await showMonthPicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );

                    if (month != null) {

                      selectedMonth = month;

                      await fetchDynamicMonthlyReport(
                        DateFormat("yyyy-MM").format(selectedMonth),
                      );
                    }
                  },
                ),

              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: monthlyDynamicFormData.isEmpty
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: getDynamicSections(
                    formData,
                    totalMonthlyDynamicForm,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: monthlyDynamicFormData.map((item) {

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: getFormColor(item["form_name"]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "${item["form_name"]} (${item["total"]})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  ],
                );

              }).toList(),
            ),

            const SizedBox(height: 12),

            Text(
              "Total Monthly Dynamic Form : $totalMonthlyDynamicForm",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

          ],
        ),
      ),
    );
  }
  //---------------------------------------------------------------
  //----
  List<Map<String,dynamic>> performanceList=[];

  Future<void> fetchPerformance() async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/weekly_team_performance.php"),
      body: {
        "cid": widget.cid,
      },
    );

    print(response.body);

    final json = jsonDecode(response.body);

    if (json["status"] == true) {
      setState(() {
        performanceList =
        List<Map<String, dynamic>>.from(json["data"]);
        print("=======================");
        print(performanceList);
        print("=======================");
      });
    }
  }
  Map<String, List<Map<String, dynamic>>> groupByBranch() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in performanceList) {
      final branch = item["branch"] ?? "Unknown";

      if (!grouped.containsKey(branch)) {
        grouped[branch] = [];
      }

      grouped[branch]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
        //backgroundColor: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        title: const Text("Dashboard",style: TextStyle(color: Colors.white,fontSize: 18,),),
        actions: [
          // ElevatedButton(onPressed: (){
          //   Get.to(
          //         () => ChatbotScreen(
          //       cid:widget.cid,
          //       uid: widget.cid,
          //       name: 'Admin',
          //       branchName: 'Admin',
          //     ),
          //   );
          // },
          //     style: ElevatedButton.styleFrom(
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(5), // Perfect square corners
          //       ),
          //     ),child: Text("Group Chat")),
          SizedBox(width: 10,),
          ElevatedButton(onPressed: (){
            Get.to(()=>AddBranchScreen(cid:widget.cid));
          },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Perfect square corners
                ),
              ),child: Text("📍 Branch Analytics",
                style: TextStyle(color: Color(0xff1D4ED8),fontFamily: 'impact',fontSize: 14),
              )),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>ShiftScreen(cid:widget.cid));
          }, style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ),child: Text("🕒 Shift Distribution",  style: TextStyle(color: Color(0xff1D4ED8),fontFamily: 'impact',fontSize: 14),)),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>DepartmentScreen(cid: widget.cid));
          },style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ), child: Text("🏢 Department Analytics",  style: TextStyle(color: Color(0xff1D4ED8),fontFamily: 'impact',fontSize: 14),)),
          SizedBox(width: 10,),
          IconButton(
            icon: const Icon(Icons.refresh_outlined,color: Colors.white,),
            onPressed: () async {
              try {
                final res = await http.get(
                  Uri.parse(
                    'http://15.206.209.30/attendance/mark_absent.php',
                  ),
                );

                if (res.statusCode == 200) {
                  final data = jsonDecode(res.body);
                  print(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? 'Success'),
                      backgroundColor: data['status'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print(e.toString());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),

          SizedBox(width: 20,)

        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Company ID: ${widget.cid}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  IconButton(onPressed: (){
                    fetchAttendance();
                    fetchTodayReport();
                    fetchTodayReport();
                    fetchDynamicFormChart();
                    fetchDynamicMonthlyReport(
                      DateFormat('yyyy-MM').format(DateTime.now()),
                    );
                    fetchMonthlyReport(
                      DateFormat('yyyy-MM').format(DateTime.now()),
                    );
                    fetchPerformance();
                  }, icon: Icon(Icons.refresh_outlined,size: 30,color: Color(0xff2563EB),))
                ],
              ),
              const SizedBox(height: 10),
             Column(
                children: [
                  Row(
                    children: [
                      Expanded(child:  attendanceChart()),
                      SizedBox(width: 20),
                      Expanded(child: userChart()),
                    ],
                  ),
                  widget.cid == "1"? Row(
                    children: [
                      Expanded(
                        child: reportChart(reportList),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: reportMonthChart(),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                  Row(
                    children: [
                      Expanded(child:  dynamicTodayFormChart(dynamicFormChart)),
                      SizedBox(width: 20),
                      Expanded(child: dynamicMonthChart()),
                    ],
                  ),


                ],
              ),
              const SizedBox(height: 10),
              widget.cid==1.toString()?Center(child: const Text("📊 Weekly Performance (Mon–Sun)",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 18),)):SizedBox.shrink(),
              const SizedBox(height: 10),
              widget.cid==1.toString()?branchPerformanceWidget():SizedBox.shrink(),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 🔵 HEADER
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff2563EB),
                    Color(0xff1D4ED8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Image.asset("assets/image/logo.png"),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "TrackMe EMS",
                    style: TextStyle(
                      color: Colors.white, // Dark Slate
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Employee Management System",
    style: TextStyle(
    color: Colors.white, // Dark Slate
    fontSize: 15,
    fontWeight: FontWeight.w600,
    ),
                  ),
                ],
              ),
            ),
            // 🟢 PROFILE
            ListTile(
              leading: Icon(Icons.person,color: Color(0xff2563EB),size: 22,),
              title: Text("Employee Directory",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(() => UsersTableScreen(cid:widget.cid)); // change to ProfileScreen if you have
              },
            ),

            // 🟢 ATTENDANCE
            ListTile(
              leading: Icon(Icons.watch_later_outlined,color: Color(0xff2563EB),size: 22,),
              title: Text("Daily Attendance",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(() => AllEmployeeAttendanceScreen(cid: widget.cid));
              },
            ),
            // 🟢 LOCATION CAPTURING
            widget.cid == "1"?ListTile(
              leading: Icon(Icons.file_open_outlined,color: Color(0xff2563EB),size: 22,),
              title: Text("Client Submissions Form",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(()=>AllFormReportScreen(cid: widget.cid,));
              },
            ):SizedBox.shrink(),
            // widget.cid==1.toString()?SizedBox.shrink():
          ListTile(
              leading: Icon(Icons.file_copy,color: Color(0xff2563EB),size: 22,),
              title: Text("Dynamic Form Management",style: TextStyle(
                color: Color(0xFF1E293B), // Dark Slate
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),),
              onTap: () {
                Get.back();
                Get.to(()=>CreateFormScreen(cid: widget.cid,));
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month,color: Color(0xff2563EB),size: 22,),
              title: Text("Work Schedule",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(()=>RosterScreen(cid: widget.cid,));
              },
            ),
            ListTile(
              leading: Icon(Icons.help_center_outlined,color: Color(0xff2563EB),size: 22,),
              title: Text("Permission",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(()=>SettingsScreen(cid: widget.cid,));
              },
            ),
            // 🟢 LOCATION REPORT
            ListTile(
              leading: Icon(Icons.location_on,color: Color(0xff2563EB),size: 22,),
              title: Text("Location Tracking",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () {
                Get.back();
                Get.to(()=>LocationHistoryScreen(cid: widget.cid,));
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications,color: Color(0xff2563EB),size: 22,),
              title: Text("Notifications",
                style: TextStyle(
                color: Color(0xFF1E293B), // Dark Slate
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),),
              onTap: () {
                Get.back();
                Get.to(()=>SendNotificationScreen(cid: widget.cid,));
              },
            ),

            const Divider(),

            // 🔴 LOGOUT
            ListTile(
              leading: Icon(Icons.logout, color: Color(0xff2563EB),size: 22,),
              title: Text("Sign Out",
                style: TextStyle(
                  color: Color(0xFF1E293B), // Dark Slate
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget branchPerformanceWidget() {
    final grouped = groupByBranch();

    if (grouped.isEmpty) {
      return const Center(
        child: Text("No Performance Data"),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 👈 2 branch in one row
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (context, index) {
        final branch = grouped.keys.elementAt(index);
        final users = grouped[branch]!;

        users.sort(
              (a, b) => (b["forms"] as int).compareTo(a["forms"] as int),
        );

        return Card(
          elevation: 3,
          child: Column(
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff2563EB),
                      Color(0xff1D4ED8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    branch,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 8,
                    horizontalMargin: 8,
                    headingRowHeight: 30,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 38,
                    columns: const [
                      DataColumn(label: Text("R")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Form")),
                      DataColumn(label: Text("%")),
                    ],
                    rows: List.generate(users.length, (i) {

                      final u = users[i];

                      String rank = switch (i) {
                        0 => "🥇",
                        1 => "🥈",
                        2 => "🥉",
                        _ => "${i + 1}",
                      };

                      return DataRow(
                        cells: [
                          DataCell(Text(rank)),
                          DataCell(
                            SizedBox(
                              width: 270,
                              child: Text(
                                u["name"].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text("${u["forms"]}")),
                          DataCell(Text("${u["performance"]}%")),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
