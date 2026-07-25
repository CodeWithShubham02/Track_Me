import 'package:flutter/material.dart';
import '../controller/department_controller.dart';
import '../model/department_model.dart';

class DepartmentScreen extends StatefulWidget {
  final String cid;
  const DepartmentScreen({required this.cid});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final DepartmentController controller = DepartmentController();
  List<DepartmentModel> departments = [];
  bool isLoading = true;

  final TextEditingController nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    final data = await controller.fetchDepartments(widget.cid);
    setState(() {
      departments = data;
      isLoading = false;
    });
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
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("User Type",style: TextStyle(color: Colors.white,fontSize: 18),),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:  Color(0xff2563EB),
        onPressed: _addDepartmentDialog,
        child: const Icon(Icons.add,color: Colors.white,),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : departments.isEmpty
          ? const Center(child: Text("No departments found"))
          : ListView.builder(
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          return Card(
            child: ListTile(
              title: Text(dept.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.edit,
                  //       color: Colors.blue),
                  //   onPressed: () =>
                  //       _editDepartmentDialog(dept),
                  // ),
                  // IconButton(
                  //   icon: const Icon(Icons.delete,
                  //       color: Colors.red),
                  //   onPressed: () =>
                  //       _deleteDepartment(dept.id),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ADD
  void _addDepartmentDialog() {
    nameCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => _departmentDialog(
        title: "Add Department",
        onSave: () async {
          final success = await controller.addDepartment(
              widget.cid, nameCtrl.text);
          if (success) {
            Navigator.pop(context);
            loadDepartments();
          }
        },
      ),
    );
  }

  /// EDIT
  void _editDepartmentDialog(DepartmentModel dept) {
    nameCtrl.text = dept.name;

    showDialog(
      context: context,
      builder: (_) => _departmentDialog(
        title: "Edit Department",
        onSave: () async {
          final success = await controller.updateDepartment(
              dept.id, nameCtrl.text);
          if (success) {
            Navigator.pop(context);
            loadDepartments();
          }
        },
      ),
    );
  }

  /// DIALOG
  Widget _departmentDialog(
      {required String title, required VoidCallback onSave}) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: nameCtrl,
        decoration:
        const InputDecoration(labelText: "Department Name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: onSave,
          child: const Text("Save"),
        ),
      ],
    );
  }

  /// DELETE
  void _deleteDepartment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Department"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteDepartment(id);
      loadDepartments();
    }
  }
}
