import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'get_form_fieldwise_screen.dart';

class AllDynamicForm extends StatefulWidget {
  final String cid;
  const AllDynamicForm({super.key, required this.cid});

  @override
  State<AllDynamicForm> createState() => _AllDynamicFormState();
}

class _AllDynamicFormState extends State<AllDynamicForm> {

  List<dynamic> templates = [];
  Future<void> getTemplates() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_templates.php?cid=${widget.cid}",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true) {
          setState(() {
            templates = json["data"];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }
  bool loading = true;
  @override
  void initState() {
    super.initState();
    getTemplates();

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
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("All Forms",style: TextStyle(color: Colors.white),),
      ),
        body: templates.isEmpty
            ? const Center(
          child: Text("No Template Found"),
        )
            : ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final item = templates[index];

            return Card(
              child: ListTile(
                title: Text(item["form_name"]),
                subtitle: Text(item["description"] ?? ""),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GetFormFieldwiseScreen(
                        templateId: item["id"].toString(),
                        cid: widget.cid,
                        formName: item["form_name"],
                      ),
                    ),
                  );
                },
              ),
            );
          },
    ),
    );
  }
  
}
