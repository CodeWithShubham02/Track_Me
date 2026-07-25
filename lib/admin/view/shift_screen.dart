import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/shift_controller.dart';
import '../model/shift_model.dart';

class ShiftScreen extends StatefulWidget {
  final String cid;
  const ShiftScreen({required this.cid});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final ShiftController controller = ShiftController();
  List<ShiftModel> shifts = [];
  bool isLoading = true;

  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadShifts();
  }

  Future<void> loadShifts() async {
    setState(() {
      isLoading = true;
    });

    final data = await controller.fetchShifts(widget.cid);

    if (!mounted) return;

    setState(() {
      shifts = data;
      isLoading = false;
    });
  }
  String _formatTime(String time24) {
    try {
      final parsedTime = DateFormat("HH:mm:ss").parse(time24);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return time24; // fallback if format unexpected
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
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Shifts Master",style: TextStyle(color: Colors.white,fontSize: 18),),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:  Color(0xff2563EB),
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add,color:  Colors.white,),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: shifts.length,
        itemBuilder: (context, index) {
          final shift = shifts[index];
          return Card(
            child: ListTile(
              title: Text(
                "${_formatTime(shift.shiftStart)} - ${_formatTime(shift.shiftEnd)}",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color:  Color(0xff2563EB)),
                    onPressed: () => _showEditDialog(shift),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.delete, color: Colors.red),
                  //   onPressed: () => _deleteShift(shift.shiftId),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    startCtrl.clear();
    endCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // prevents outside close
      builder: (_) => _shiftDialog(
        title: "Add Shift 24hr pr wise add shift",
        onSave: () async {
          final success = await controller.addShift(
            widget.cid,
            startCtrl.text.trim(),
            endCtrl.text.trim(),
          );

          if (success) {
            Navigator.of(context, rootNavigator: true).pop(); // close dialog
            await loadShifts(); // refresh list

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Shift Added Successfully")),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(ShiftModel shift) {
    startCtrl.text = shift.shiftStart;
    endCtrl.text = shift.shiftEnd;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _shiftDialog(
        title: "Edit Shift",
        onSave: () async {
          final success = await controller.updateShift(
            shift.shiftId,
            startCtrl.text.trim(),
            endCtrl.text.trim(),
          );

          if (success) {
            Navigator.of(context, rootNavigator: true).pop();
            await loadShifts();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Shift Updated Successfully")),
            );
          }
        },
      ),
    );
  }

  Widget _shiftDialog(
      {required String title,
        required Future<void> Function() onSave,}) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: startCtrl,
            decoration:
            const InputDecoration(labelText: "Start (HH:mm)"),
          ),
          TextField(
            controller: endCtrl,
            decoration:
            const InputDecoration(labelText: "End (HH:mm)"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: onSave, child: const Text("Save")),
      ],
    );
  }

  void _deleteShift(String shiftId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Shift"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await controller.deleteShift(shiftId);

      if (success) {
        await loadShifts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shift Deleted Successfully")),
        );
      }
    }
  }
}
