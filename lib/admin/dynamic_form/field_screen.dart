import 'package:flutter/material.dart';

import 'addfield_dialog.dart';
import 'field_controller.dart';

class FieldScreen extends StatefulWidget {
  final String templateId;
  final String cid;
  final String formName;
  const FieldScreen({super.key, required this.cid,required this.templateId, required this.formName});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  List<dynamic> fields = [];

  Map<String, dynamic>? selectedField;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFields();
  }

  Future<void> loadFields() async {

    loading = true;

    setState(() {});

    fields = await FieldController.getFields(widget.templateId);

    loading = false;

    setState(() {});
  }
  void showAddOptionDialog() {

    TextEditingController optionController =
    TextEditingController();

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: Text(
            "Add Option (${selectedField!["field_label"]})",
          ),

          content: TextField(

            controller: optionController,

            decoration: const InputDecoration(

              border: OutlineInputBorder(),

              labelText: "Option",

            ),

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text("Cancel"),

            ),

            ElevatedButton(

              onPressed: () async {

                if(optionController.text.trim().isEmpty){

                  return;

                }

                bool success =
                await FieldController.addOption(

                  fieldId:
                  selectedField!["id"].toString(),

                  optionValue:
                  optionController.text.trim(),

                );

                if(success){

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      backgroundColor: Colors.green,

                      content: Text(
                        "Option Added Successfully",
                      ),

                    ),

                  );

                }

              },

              child: const Text("Save"),

            )

          ],

        );

      },

    );

  }
  void showEditFieldDialog(Map<String, dynamic> field) {

    TextEditingController label =
    TextEditingController(text: field["field_label"]);

    TextEditingController name =
    TextEditingController(text: field["field_name"]);

    TextEditingController order =
    TextEditingController(
      text: field["sort_order"].toString(),
    );

    bool required =
        field["is_required"].toString() == "1";

    String type = field["field_type"];

    showDialog(

      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setDialog) {

            return AlertDialog(

              title: const Text("Edit Field"),

              content: SizedBox(

                width: 400,

                child: SingleChildScrollView(

                  child: Column(

                    children: [

                      TextField(

                        controller: label,

                        decoration: const InputDecoration(
                          labelText: "Field Label",
                        ),

                      ),

                      const SizedBox(height: 10),

                      TextField(

                        controller: name,

                        decoration: const InputDecoration(
                          labelText: "Field Name",
                        ),

                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField(

                        value: type,

                        items: const [

                          DropdownMenuItem(
                            value: "text",
                            child: Text("Text"),
                          ),

                          DropdownMenuItem(
                            value: "number",
                            child: Text("Number"),
                          ),

                          DropdownMenuItem(
                            value: "dropdown",
                            child: Text("Dropdown"),
                          ),

                          DropdownMenuItem(
                            value: "image",
                            child: Text("Image"),
                          ),

                        ],

                        onChanged: (v) {

                          setDialog(() {

                            type = v!;

                          });

                        },

                      ),

                      CheckboxListTile(

                        value: required,

                        title: const Text("Required"),

                        onChanged: (v) {

                          setDialog(() {

                            required = v!;

                          });

                        },

                      ),

                      TextField(

                        controller: order,

                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(
                          labelText: "Sort Order",
                        ),

                      ),

                    ],

                  ),

                ),

              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(context);

                  },

                  child: const Text("Cancel"),

                ),

                ElevatedButton(

                  onPressed: () {

                    /// update_field.php

                    Navigator.pop(context);

                  },

                  child: const Text("Update"),

                ),

              ],

            );

          },

        );

      },

    );

  }
  void showDeleteDialog(
      Map<String, dynamic> field,
      ) {

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: const Text("Delete Field"),

          content: Text(
            "Delete '${field["field_label"]}' ?",
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text("Cancel"),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),

              onPressed: () async {

                /*
              bool success =
              await FieldController.deleteField(
                  field["id"].toString());

              if(success){

                loadFields();

              }
              */

                Navigator.pop(context);

              },

              child: const Text("Delete"),

            ),

          ],

        );

      },

    );

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(widget.formName,style: TextStyle(color: Colors.white),),

            if (selectedField != null)
              Text(
                "Selected : ${selectedField!["field_label"]}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),

          ],
        ),

        actions: [

          IconButton(
            tooltip: "Add Option",
            icon: const Icon(Icons.playlist_add),
            onPressed: () {

              if (selectedField == null) {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a field"),
                  ),
                );

                return;
              }

              if (selectedField!["field_type"] != "dropdown") {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Options can only be added to Dropdown fields",
                    ),
                  ),
                );

                return;
              }

              showAddOptionDialog();

            },
          ),

        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Field"),
        onPressed: () {

          showDialog(
            context: context,
            builder: (_) => AddFieldDialog(
              templateId: widget.templateId,
              onSuccess: () async {
                await loadFields();
              },
            ),
          );

        },
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : fields.isEmpty
          ? const Center(
        child: Text(
          "No Fields Found",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: fields.length,
        itemBuilder: (context, index) {

          final field = fields[index];

          return buildFieldCard(field, index);

        },
      ),
    );
  }
  Widget buildFieldCard(
      Map<String, dynamic> field,
      int index,
      ) {

    return Card(

      color: selectedField?["id"] == field["id"]
          ? Colors.blue.shade50
          : Colors.white,

      elevation: 3,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: InkWell(

        borderRadius: BorderRadius.circular(12),

        onTap: () {

          setState(() {

            selectedField = field;

          });

        },

        child: ListTile(

          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              "${index + 1}",
              style: const TextStyle(color: Colors.white),
            ),
          ),

          title: Text(
            field["field_label"],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 5),

              Text("Field Name : ${field["field_name"]}"),

              Text("Type : ${field["field_type"]}"),

              Text(
                field["is_required"].toString() == "1"
                    ? "Required"
                    : "Optional",
                style: TextStyle(
                  color:
                  field["is_required"].toString() == "1"
                      ? Colors.red
                      : Colors.green,
                ),
              ),

            ],
          ),

          trailing: PopupMenuButton<String>(

            onSelected: (value) {

              switch (value) {

                case "edit":

                  showEditFieldDialog(field);

                  break;

                case "delete":

                  showDeleteDialog(field);

                  break;

                case "option":

                  setState(() {
                    selectedField = field;
                  });

                  showAddOptionDialog();

                  break;

              }

            },

            itemBuilder: (_) => [

              const PopupMenuItem(
                value: "edit",
                child: Text("Edit"),
              ),

              const PopupMenuItem(
                value: "delete",
                child: Text("Delete"),
              ),

              if (field["field_type"] == "dropdown")
                const PopupMenuItem(
                  value: "option",
                  child: Text("Manage Options"),
                ),

            ],

          ),

        ),

      ),

    );

  }
}
