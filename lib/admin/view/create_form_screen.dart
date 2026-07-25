import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import '../dynamic_form/all_dyanmic_form.dart';
import '../dynamic_form/create_form_template_controller.dart';
import 'package:http/http.dart' as http;

import '../dynamic_form/field_screen.dart';
class CreateFormScreen extends StatefulWidget {
  final String cid;

  const CreateFormScreen({
    super.key,
    required this.cid,
  });

  @override
  State<CreateFormScreen> createState() => _CreateFormScreenState();
}

class _CreateFormScreenState extends State<CreateFormScreen> {
  final TextEditingController formNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Temporary List
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
  void _showCreateTemplateDialog() {
    formNameController.clear();
    descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Form Template"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: formNameController,
                  decoration: const InputDecoration(
                    labelText: "Form Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                if (formNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter Form Name"),
                    ),
                  );
                  return;
                }

                bool success = await createFormTemplate(
                  cid: widget.cid,
                  formName: formNameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                if(success){

                  Navigator.pop(context);

                  await getTemplates();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Template Created Successfully"),
                    ),
                  );

                }
              },
            ),
          ],
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
    getTemplates();
  }
  @override
  void dispose() {
    formNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateFormStatus(
      String templateId,
      bool status,
      ) async {

    final response = await http.post(
      Uri.parse(
        "http://15.206.209.30/attendance/update_form_status.php",
      ),
      body: {
        "template_id": templateId,
        "status": status ? "1" : "0",
      },
    );

    final json = jsonDecode(response.body);

    if (json["status"] == true) {
      getTemplates(); // Reload list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json["message"])),
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
        title: const Text(
          "Dynamic Form Management",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: (){
                Get.to(()=>AllDynamicForm(cid: widget.cid,));
              },
              child: const Text("All Forms"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton(
              onPressed: _showCreateTemplateDialog,
              child: const Text("Create Form"),
            ),
          ),
        ],
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
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(item["form_name"]),
              subtitle: Text(item["description"] ?? ""),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Text(
                    item["status"].toString() == "1"
                        ? "Active"
                        : "Inactive",
                    style: TextStyle(
                      color: item["status"].toString() == "1"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Switch(
                    value: item["status"].toString() == "1",
                    activeColor: Colors.green,
                    onChanged: (value) {
                      updateFormStatus(
                        item["id"].toString(),
                        value,
                      );
                    },
                  ),
                ],
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FieldScreen(
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