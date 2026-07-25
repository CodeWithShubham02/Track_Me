import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';

class InactiveBranchSheet extends StatefulWidget {
  final String cid;

  const InactiveBranchSheet({
    super.key,
    required this.cid,
  });

  @override
  State<InactiveBranchSheet> createState() =>
      _InactiveBranchSheetState();
}

class _InactiveBranchSheetState
    extends State<InactiveBranchSheet> {

  final controller = BranchController();

  late Future<List<BranchModel>> future;

  @override
  void initState() {
    super.initState();
    future =getInactiveBranches(widget.cid);
  }
  Future<List<BranchModel>> getInactiveBranches(String cid) async {
    final response = await http.get(
      Uri.parse("http://15.206.209.30/attendance/get_inactive_branch.php?cid=$cid"),
    );

    final data = jsonDecode(response.body);

    if (data["status"] == true) {
      return (data["data"] as List)
          .map((e) => BranchModel.fromJson(e))
          .toList();
    }

    return [];
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .75,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            const Text(
              "Inactive Kiosk",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: FutureBuilder<List<BranchModel>>(
                future: future,
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No inactive kiosk"),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) {

                      final b = snapshot.data![index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.location_city,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(b.branchName),
                          subtitle: Text(
                            "Distance : ${b.distance}",
                          ),
                          trailing: IconButton(
                            onPressed: (){},
                            icon: const Icon(Icons.settings),
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}