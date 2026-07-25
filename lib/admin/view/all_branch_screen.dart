import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';
import 'branch_screen.dart';
import 'edit_branch_screen.dart';
import 'inactive_branch_sheet.dart';

class BranchListScreen extends StatefulWidget {
  final String cid;
  const BranchListScreen({super.key, required this.cid});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  final controller = BranchController();
  late Future<List<BranchModel>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = controller.getBranches(widget.cid);
    setState(() {});
  }

  void delete(String id) async {
    final ok = await controller.deleteBranch(id);
    if (ok) refresh();
    Get.snackbar(
      "Inactive",
      "Branch inactive successfully",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.delete, color: Colors.white),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor:Colors.blue,
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
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          title: const Text("All Kiosk",style: TextStyle(color: Colors.white,fontSize: 18,fontFamily: 'impact'),),
        actions: [
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                builder: (_) => InactiveBranchSheet(cid: widget.cid),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text("Inactive Kiosk"),
          ),
          SizedBox(width: 20,)
        ],
      ),

      body: FutureBuilder<List<BranchModel>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) {
            return const Center(child: Text("No branches"));
          }

          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (context, i) {
              final b = snap.data![i];
              return Card(
                child: ListTile(
                  title: Text(b.branchName),
                  subtitle: Text("Distance: ${b.distance}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color:  Color(0xff2563EB)),
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBranchScreen(branch: b),
                            ),
                          );
                          if (res == true) refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.red),
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Inactivate Kiosk"),
                                content: Text("Are you sure you want to inactive this kiosk?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false), // ❌ Cancel
                                    child: Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor:  Color(0xff2563EB)),
                                    onPressed: () => Navigator.pop(context, true), // ✅ Confirm
                                    child: Text("Inactivate",style: TextStyle(color: Colors.white),),
                                  ),
                                ],
                              );
                            },
                          ) ?? false;

                          if (confirm) {
                            delete(b.id); // ✅ Call your function
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
