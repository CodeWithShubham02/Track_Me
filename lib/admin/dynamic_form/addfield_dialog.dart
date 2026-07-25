import 'package:flutter/material.dart';
import 'field_controller.dart';

class AddFieldDialog extends StatefulWidget {
  final String templateId;
  final VoidCallback onSuccess;

  const AddFieldDialog({
    super.key,
    required this.templateId,
    required this.onSuccess,
  });

  @override
  State<AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<AddFieldDialog> {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController orderController =
  TextEditingController(text: "1");

  bool isLoading = false;
  bool required = true;

  String selectedType = "text";

  final List<String> fieldTypes = [
    "text",
    "number",
    "dropdown",
    "image",
  ];

  @override
  void dispose() {
    labelController.dispose();
    nameController.dispose();
    orderController.dispose();
    super.dispose();
  }

  Future<void> saveField() async {
    if (labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please Enter Field Label"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await FieldController.addField(
      templateId: widget.templateId,
      fieldLabel: labelController.text.trim(),
      fieldName: nameController.text.trim(),
      fieldType: selectedType,
      isRequired: required ? "1" : "0",
      sortOrder: orderController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pop(context);

      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Field Added Successfully"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to Add Field"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Field"),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: "Field Label",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  nameController.text = value
                      .trim()
                      .toLowerCase()
                      .replaceAll(" ", "_");
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Field Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Field Type",
                  border: OutlineInputBorder(),
                ),
                items: fieldTypes.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Sort Order",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: required,
                title: const Text("Required Field"),
                onChanged: (value) {
                  setState(() {
                    required = value!;
                  });
                },
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

        ElevatedButton.icon(
          onPressed: isLoading ? null : saveField,
          icon: isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.save),
          label: Text(isLoading ? "Saving..." : "Save"),
        ),
      ],
    );
  }
}