import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/team_leader_model.dart';

class SettingsScreen extends StatefulWidget {
  final String cid;

  const SettingsScreen({
    super.key,
    required this.cid,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool isLoading = true;

  List<TeamLeaderModel> teamLeaders = [];

  @override
  void initState() {
    super.initState();
    getTeamLeaders();
  }

  Future<void> getTeamLeaders() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_team_leaders.php?cid=${widget.cid}",
        ),
      );

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        teamLeaders = (json["data"] as List)
            .map((e) => TeamLeaderModel.fromJson(e))
            .toList();
      }

    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> updateFeatureAccess({
    required String tlId,
    required String cid,
    required String featureName,
    required bool value,
  }) async {
print(tlId.toString());
print(cid.toString());
print(featureName.toString());
print(value.toString());
final response = await http.post(
  Uri.parse(
    "http://15.206.209.30/attendance/update_feature_access.php",
  ),
  body: {
    "tl_id": tlId,
    "cid": cid,
    "feature_name": featureName,
    "status": value ? "1" : "0",
  },
);
//mai chahata hu ki vh user active rahe jab tk switch na htaaye
print(response);
print(response.body);
    final json = jsonDecode(response.body);

    if (json["status"] != true) {
      throw Exception(json["message"]);
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Update Shift Permission",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: teamLeaders.length,
        itemBuilder: (context, index) {

          final item = teamLeaders[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(

              leading: CircleAvatar(
                child: Text(
                  item.fullName[0].toUpperCase(),
                ),
              ),

              title: Text(item.fullName),

              subtitle: Text(item.userId),
              trailing: Switch(
                value: item.featureStatus,
                onChanged: (value) async {

                  bool oldValue = item.featureStatus;

                  setState(() {
                    item.featureStatus = value;
                  });

                  try {

                    await updateFeatureAccess(
                      tlId: item.uid,
                      cid: item.cid,
                      featureName: "UpdateUserShiftScreen",
                      value: value,
                    );

                  } catch (e) {

                    setState(() {
                      item.featureStatus = oldValue;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}