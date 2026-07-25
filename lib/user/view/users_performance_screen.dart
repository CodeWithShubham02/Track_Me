import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersPerformanceScreen extends StatefulWidget {
  final String branchName;
  final String cid;
  const UsersPerformanceScreen({super.key, required this.branchName,required this.cid});

  @override
  State<UsersPerformanceScreen> createState() => _UsersPerformanceScreenState();
}

class _UsersPerformanceScreenState extends State<UsersPerformanceScreen> {
  @override
  void initState() {
    super.initState();
    fetchPerformance();
  }
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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("User Performance",style: TextStyle(color: Colors.white,fontSize: 18),),
      ),
        body: performanceList.isEmpty
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Weekly Performance (Mon - Sun)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  branchPerformanceWidget(),
                ],
              ),
            ),
          ),
        ),
    );
  }
  Widget branchPerformanceWidget() {
    final grouped = groupByBranch();

    if (grouped.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!grouped.containsKey(widget.branchName)) {
      return const Center(
        child: Text("No Performance Data"),
      );
    }

    final users = grouped[widget.branchName]!;

    users.sort(
          (a, b) => (b["forms"] as int).compareTo(a["forms"] as int),
    );

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                widget.branchName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 15,
              columns: const [
                DataColumn(label: Text("R")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Forms")),
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
                        width: 150,
                        child: Text(
                          u["name"],
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
        ],
      ),
    );
  }
}
