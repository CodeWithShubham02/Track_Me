import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../controller/branch_controller.dart';
import 'all_branch_screen.dart';

class AddBranchScreen extends StatefulWidget {
  final String cid;

  const AddBranchScreen({super.key, required this.cid});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final BranchController controller = BranchController();

  final nameCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final longCtrl = TextEditingController();

  bool isLoading = false;

  void saveBranch() async {
    if (nameCtrl.text.trim().isEmpty ||
        distanceCtrl.text.trim().isEmpty ||
        latCtrl.text.trim().isEmpty ||
        longCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter all fields."),
        ),
      );
      return;
    }
    setState(() => isLoading = true);

    final success = await controller.addBranch(
      branchName: nameCtrl.text.trim(),
      distance: distanceCtrl.text.trim(),
      cid: widget.cid,
      lat: latCtrl.text.trim(),
      long: longCtrl.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add branch")),
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
        iconTheme: IconThemeData(
          color: Colors.white
        ),
          backgroundColor: Colors.blue,title: const Text("Kiosk Management",style: TextStyle(color: Colors.white,fontSize: 18),),
        actions: [
          ElevatedButton(onPressed: (){
            Get.to(()=>BranchListScreen(cid: widget.cid));
          }, style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ),child: Text("Manage Kiosks")),
          SizedBox(width: 20,)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔹 Row 1 → Kiosk Name + Distance
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Kiosk Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: distanceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Distance",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🔹 Row 2 → Latitude + Longitude
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: longCtrl,
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Button
            ElevatedButton(
              onPressed: isLoading ? null : saveBranch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1D4ED8),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
