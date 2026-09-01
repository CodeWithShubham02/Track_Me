import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  List<dynamic> featureAccessList = [];
  List<dynamic> teamLeaderList = [];

  @override
  void initState() {
    super.initState();
    getFeatureAccess();

  }

  // =========================================================
  // GET FEATURE ACCESS
  // =========================================================

  Future<void> getFeatureAccess() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/get_feature_access.php",
        ),
        body: {
          "cid": widget.cid,
        },
      );

      debugPrint(
        "Feature Access Status: ${response.statusCode}",
      );

      debugPrint(
        "Feature Access Response: ${response.body}",
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (mounted) {
          setState(() {
            featureAccessList = data['data'] ?? [];
          });
        }
      } else {
        throw Exception(
          data['message'] ?? "Unable to get feature access",
        );
      }
    } catch (e) {
      debugPrint("Feature Access Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst("Exception: ", ""),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //=========================================================
  // fetch Team Leaders
  //=========================================================
  Future<void> getTeamLeaders() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/get_team_leaders.php?cid=${widget.cid}",
        ),
      );

      debugPrint(
        "Team Leader Status: ${response.statusCode}",
      );

      debugPrint(
        "Team Leader Response: ${response.body}",
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        setState(() {
          teamLeaderList = data['data'] ?? [];
        });
      } else {
        throw Exception(
          data['message'] ?? "Unable to get team leaders",
        );
      }
    } catch (e) {
      debugPrint("Team Leader Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst("Exception: ", ""),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
// =========================================================
  // ADD TEAM LEADER DIALOG
  // =========================================================

  Future<void> showAddTeamLeaderDialog() async {
    // API call before opening dialog
    await getTeamLeaders();

    if (!mounted) return;

    String? selectedTlId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Add Team Leader",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SizedBox(
                width: double.maxFinite,

                child: teamLeaderList.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No active Team Leader found",
                  ),
                )
                    : DropdownButtonFormField<String>(
                  value: selectedTlId,

                  decoration: const InputDecoration(
                    labelText: "Select Team Leader",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.person,
                    ),
                  ),

                  isExpanded: true,

                  items: teamLeaderList.map<DropdownMenuItem<String>>(
                        (item) {
                      return DropdownMenuItem<String>(
                        value: item['uid'].toString(),

                        child: Text(
                          "${item['full_name']} (${item['userid']})",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),

                  onChanged: (value) {
                    setDialogState(() {
                      selectedTlId = value;
                    });
                  },
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(
                  onPressed: selectedTlId == null
                      ? null
                      : () async {
                    final selectedTeamLeader = teamLeaderList.firstWhere(
                          (item) => item['uid'].toString() == selectedTlId,
                    );

                    final tlId = selectedTeamLeader['uid'].toString();
                    final cid = selectedTeamLeader['cid'].toString();
                    const featureName = "UpdateUserShiftScreen";

                    debugPrint("Selected tl_id: $tlId");
                    debugPrint("Selected cid: $cid");
                    debugPrint("Selected feature_name: $featureName");

                    try {
                      final response = await http.post(
                        Uri.parse(
                          "http://15.206.209.30/attendance/add_feature_access.php",
                        ),
                        body: {
                          "tl_id": tlId,
                          "cid": cid,
                          "feature_name": featureName,
                          "status": "0",
                        },
                      );

                      final data = jsonDecode(response.body);

                      if (data["success"] == true) {
                        if (context.mounted) {
                          Navigator.pop(context, true);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Feature added successfully"),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                data["message"] ?? "Feature already exists",
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint("Error: $e");

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Something went wrong"),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Add"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // UPDATE FEATURE STATUS
  // =========================================================

  Future<void> updateFeatureStatus({
    required String tlId,
    required String cid,
    required String featureName,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse(
        "http://15.206.209.30/attendance/update_feature_access.php",
      ),
      body: {
        "tl_id": tlId,
        "cid": cid,
        "feature_name": featureName,
        "status": status,
      },
    );

    debugPrint(
      "Update Feature Status: ${response.statusCode}",
    );

    debugPrint(
      "Update Feature Response: ${response.body}",
    );

    final data = jsonDecode(response.body);

    if (data['status'] != true) {
      throw Exception(
        data['message'] ?? "Feature update failed",
      );
    }
  }
  // =========================================================
  // BUILD
  // =========================================================

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
        actions: [
          IconButton(
            onPressed: showAddTeamLeaderDialog,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : featureAccessList.isEmpty
          ? RefreshIndicator(
        onRefresh: getFeatureAccess,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 250),
            Center(
              child: Text(
                "No feature permission found",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: getFeatureAccess,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: featureAccessList.length,
          itemBuilder: (context, index) {
            final item = featureAccessList[index];

            final String status =
                item['status']?.toString() ?? "0";

            final bool isActive = status == "1";

            final String featureName =
                item['feature_name']?.toString() ?? "";

            final String tlId =
                item['tl_id']?.toString() ?? "";

            final String teamLeaderName =
                item['team_leader_name']?.toString() ?? "";

            final String teamLeaderUserId =
                item['team_leader_userid']?.toString() ?? "";

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: ListTile(
                  // =================================================
                  // LEADING
                  // =================================================

                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isActive
                        ? Colors.green
                        : Colors.grey,
                    child: Icon(
                      isActive
                          ? Icons.check
                          : Icons.block,
                      color: Colors.white,
                    ),
                  ),

                  // =================================================
                  // TITLE
                  // =================================================

                  title: Text(
                    teamLeaderName.isNotEmpty
                        ? teamLeaderName
                        : "Unknown Team Leader",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // =================================================
                  // SUBTITLE
                  // =================================================

                  subtitle: Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User ID: $teamLeaderUserId",
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),

                        Text(
                          "TL ID: $tlId",
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Feature: $featureName",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          isActive
                              ? "Permission Active"
                              : "Permission Inactive",
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive
                                ? Colors.green
                                : Colors.red,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================
                  // SWITCH
                  // =================================================

                  trailing: Switch(
                    value: isActive,

                    activeColor: Colors.green,

                    onChanged: (value) async {
                      final oldStatus =
                          item['status']?.toString() ?? "0";

                      final newStatus = value ? "1" : "0";

                      // Optimistic update
                      setState(() {
                        item['status'] = newStatus;
                      });

                      try {
                        await updateFeatureStatus(
                          tlId: item['tl_id'].toString(),
                          cid: item['cid'].toString(),
                          featureName: item['feature_name'].toString(),
                          status: newStatus,
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? "Permission Activated"
                                  : "Permission Deactivated",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        // API failed → rollback
                        if (!mounted) return;

                        setState(() {
                          item['status'] = oldStatus;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst(
                                "Exception: ",
                                "",
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}