import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';

class EditBranchScreen extends StatefulWidget {
  final BranchModel branch;
  const EditBranchScreen({super.key, required this.branch});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  final controller = BranchController();

  late TextEditingController nameCtrl;
  late TextEditingController distCtrl;
  late TextEditingController latCtrl;
  late TextEditingController longCtrl;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.branch.branchName);
    distCtrl = TextEditingController(text: widget.branch.distance);
    latCtrl = TextEditingController(text: widget.branch.lat);
    longCtrl = TextEditingController(text: widget.branch.long);
  }

  void update() async {
    setState(() => isLoading = true);

    final ok = await controller.updateBranch({
      "id": widget.branch.id,
      "branch_name": nameCtrl.text,
      "distance": distCtrl.text,
      "branch_lat": latCtrl.text,
      "branch_long": longCtrl.text,
    });

    setState(() => isLoading = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Update failed")));
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
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text("Edit Kiosk",style: TextStyle(color: Colors.white,fontSize: 18),)),
      body: SingleChildScrollView(
        child: Padding(
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
                        controller: distCtrl,
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
        
              // 🔹 Update Button
              ElevatedButton(
                onPressed: isLoading ? null : update,
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xff2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
