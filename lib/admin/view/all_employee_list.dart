import 'dart:convert';
import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/view/add_user_screen.dart';
import 'package:joizone/admin/view/inactive_user_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../controller/user_controller.dart';
import '../model/user_model.dart';
import 'package:http/http.dart' as http;
class UsersTableScreen extends StatefulWidget {
  final String cid;
  const UsersTableScreen({super.key, required this.cid});

  @override
  State<UsersTableScreen> createState() => _UsersTableScreenState();
}

class _UsersTableScreenState extends State<UsersTableScreen> {
  final UserController controller = UserController();
  bool isLoading = true;
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadData();
  }

  Future<void> loadUsers() async {
    users = await controller.fetchUsersByCid1(widget.cid);
    filteredUsers = users;

    branchList = users
        .map((e) => e.branchName)
        .toSet()
        .toList();

    setState(() => isLoading = false);
  }
  List<String> states = [];
  List<String> cities = [];
  String? selectedCities;
  String? selectedState;
  Future<void> loadData() async {
    final stateRes = await rootBundle.loadString('assets/states.json');
    final cityRes = await rootBundle.loadString('assets/cities.json');

    setState(() {
      states = List<String>.from(jsonDecode(stateRes));
      cities = List<String>.from(jsonDecode(cityRes));
    });
  }
  void editUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        // Create controllers for all fields
        final uidController = TextEditingController(text: user.uid);
        final cidController = TextEditingController(text: user.cid);
        final userIdController = TextEditingController(text: user.userid);
        final passwordController = TextEditingController(text: user.password);
        final userTokenController = TextEditingController(text: user.userToken);
        final userImgController = TextEditingController(text: user.userImg);
        final imeiNoController = TextEditingController(text: user.imeiNo);
        final fullNameController = TextEditingController(text: user.fullName);

        final cityNameController = TextEditingController(text: user.cityName);
        final stateNameController = TextEditingController(text: user.districtName);
        final pinCodeController = TextEditingController(text: user.pinCode);

        final emailController = TextEditingController(text: user.userEmail);
        final phoneController = TextEditingController(text: user.userPhone);
        final genderController = TextEditingController(text: user.gender);
        final addressController = TextEditingController(text: user.fullAddress);
        final branchIdController = TextEditingController(text: user.branchId);
        final branchNameController = TextEditingController(text: user.branchName);
        final branchDistanceController =
        TextEditingController(text: user.branchDistance);
        final branchLatController = TextEditingController(text: user.branchLat);
        final branchLongController = TextEditingController(text: user.branchLong);
        final deptIdController = TextEditingController(text: user.departmentId);
        final deptNameController =
        TextEditingController(text: user.departmentName);
        final shiftIdController = TextEditingController(text: user.shiftId);
        final shiftStartController = TextEditingController(text: user.shiftStart);
        final shiftEndController = TextEditingController(text: user.shiftEnd);
        final joiningDateController =
        TextEditingController(text: user.dateOfJoining);
        final statusController = TextEditingController(text: user.status);
        final roleController = TextEditingController(text: user.role);
        final createdAtController = TextEditingController(text: user.createdAt);
        final lastDayController = TextEditingController(text: user.lastworkingdate);
        String selectedStatus = statusController.text.isNotEmpty
            ? statusController.text
            : "active"; // default
        bool isUpdating = false;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Employee"),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(labelText: "Full Name",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Phone",border: OutlineInputBorder())),
                    SizedBox(height: 10,),

                    DropdownSearch<String>(
                      items: states,
                      selectedItem: stateNameController.text.isNotEmpty
                          ? stateNameController.text
                          : null,

                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                      ),

                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "State Name",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                          stateNameController.text = value ?? "";
                        });
                      },
                    ),
                    SizedBox(height: 10,),
                    DropdownSearch<String>(
                      items: cities,
                      selectedItem: cityNameController.text.isNotEmpty
                          ? cityNameController.text
                          : null,

                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                      ),

                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "City Name",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          selectedCities = value;
                          cityNameController.text = value ?? "";
                        });
                      },
                    ),
                    SizedBox(height: 10,),
                    TextField(
                        controller: pinCodeController,
                        decoration: const InputDecoration(labelText: "Pin Code",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(),
                      ),
                      items: ["active", "inactive"].map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                          statusController.text = value; // update controller
                        });
                      },
                    ),
                    SizedBox(height: 10,),
                    TextField(
                      controller: lastDayController,
                      readOnly: true, // Keyboard open nahi hoga
                      decoration: const InputDecoration(
                        labelText: "Last Working Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          lastDayController.text =
                              DateFormat('dd-MM-yyyy').format(pickedDate);
                        }
                      },
                    ),
                    SizedBox(height: 10,),
                    TextField(
                        controller: imeiNoController,
                        decoration: const InputDecoration(labelText: "IMEI No",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: branchNameController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Branch",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: branchDistanceController,
                        decoration: const InputDecoration(labelText: "Distance",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: branchLatController,
                        decoration: const InputDecoration(labelText: "Lat",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: branchLongController,
                        decoration: const InputDecoration(labelText: "Long",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: deptNameController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Department",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: shiftStartController,
                       // readOnly: true,
                        decoration: const InputDecoration(labelText: "Shift Start",border: OutlineInputBorder())),
                    SizedBox(height: 10,),
                    TextField(
                        controller: shiftEndController,
                       // readOnly: true,
                        decoration: const InputDecoration(labelText: "Shift End",border: OutlineInputBorder())),
                    SizedBox(height: 10,),


                    // Add more fields if needed
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  setState(() => isUpdating = true);
                  bool success = await UserController().updateUser(
                    uid: uidController.text,
                    cid: cidController.text,
                    userid: userIdController.text,
                    password: passwordController.text,
                    userToken: userTokenController.text,
                    userImg: userImgController.text,
                    imeiNo: imeiNoController.text,
                    fullName: fullNameController.text,
                    cityName: cityNameController.text,
                    stateName: stateNameController.text,
                    pinCode: pinCodeController.text,
                    userEmail: emailController.text,
                    userPhone: phoneController.text,
                    gender: genderController.text,
                    fullAddress: addressController.text,
                    branchId: branchIdController.text,
                    branchName: branchNameController.text,
                    branchDistance: branchDistanceController.text,
                    branchLat: branchLatController.text,
                    branchLong: branchLongController.text,
                    departmentId: deptIdController.text,
                    departmentName: deptNameController.text,
                    lastWorkingDate: lastDayController.text,
                    shiftId: shiftIdController.text,
                    shiftStart: shiftStartController.text,
                    shiftEnd: shiftEndController.text,
                    dateOfJoining: joiningDateController.text,
                    status: statusController.text,
                    role: roleController.text,
                    createdAt: createdAtController.text,
                  );

                  setState(() => isUpdating = false);

                  if (success) {
                    Navigator.pop(context);
                    await loadUsers(); // reload table
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User updated successfully")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Update failed")));
                  }
                },
                child: isUpdating
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> downloadExcel() async {
    if (users.isEmpty) {
      Get.snackbar("No Data", "No attendance data to export");
      return;
    }

    var excel = Excel.createExcel();

    final Sheet sheet = excel['Users_list'];

// Then delete all other sheets
    for (var sheetName in List.from(excel.tables.keys)) {
    if (sheetName != 'Users_list') {
    excel.delete(sheetName);
    }
    }

    // Header Row
    sheet.appendRow([
      // TextCellValue("UID"),
      // TextCellValue("Created Date"),
      // TextCellValue("Updated date"),
      TextCellValue("User Id"),
      TextCellValue("Full Name"),
      TextCellValue("Employee Id"),
      TextCellValue("Contact Number"),
      TextCellValue("Email Address"),
      TextCellValue("Date Of Joining"),
      TextCellValue("Office Address"),
      TextCellValue("Home State"),
      TextCellValue("City Name"),

      //TextCellValue("Password"),

      TextCellValue("Image"),




      TextCellValue("Gender"),
      TextCellValue("Reporting Position Name"),
      TextCellValue("Reporting Manager Id"),
      TextCellValue("Reporting Manager Name"),
      TextCellValue("IMEI"),
      TextCellValue("User Type"),
      TextCellValue("Status"),

      // TextCellValue("Full Address"),
      // TextCellValue("Pin Code"),
      // TextCellValue("Distance"),
      // TextCellValue("Office Lat"),
      // TextCellValue("Office Lng"),

      // TextCellValue("Shift Start"),
      // TextCellValue("Shift End"),

      // TextCellValue("Last Working Date"),

      //TextCellValue("Role"),


    ]);

    // 🔵 DATA ROWS
// 🔵 DATA ROWS
    for (var u in users) {

      sheet.appendRow([
        // TextCellValue(u.uid ?? ""),
        // TextCellValue(
        //   u.createdAt != null
        //       ? "${DateFormat('dd MMM yyyy').format(DateTime.parse(u.createdAt!))} "
        //       "${DateFormat('hh:mm a').format(DateTime.parse(u.createdAt!))}"
        //       : "",
        // ),
        // TextCellValue(
        //   u.updatedAt != null
        //       ? "${DateFormat('dd MMM yyyy').format(DateTime.parse(u.updatedAt!))} "
        //       "${DateFormat('hh:mm a').format(DateTime.parse(u.updatedAt!))}"
        //       : "",
        // ),
        TextCellValue(u.userid ?? ""),
        TextCellValue("${u.fullName ?? ""} ${u.lastName ?? ""}"),
        TextCellValue(u.userid ?? ""),
        TextCellValue(u.userPhone ?? ""),
        TextCellValue(u.userEmail ?? ""),
        TextCellValue(u.dateOfJoining ?? ""),
        TextCellValue(u.branchName ?? ""),
        TextCellValue(u.districtName ?? ""),
        TextCellValue(u.cityName ?? ""),

        //TextCellValue(u.password ?? ""),

        TextCellValue(u.userImg ?? ""),




        TextCellValue(u.gender ?? ""),
        TextCellValue(
          (() {
            try {
              final tl = users.firstWhere(
                    (e) =>
                e.branchName == u.branchName &&
                    e.departmentName == "Team Leader",
              );
              return "Reporting Manager (${tl.branchName})";
            } catch (e) {
              return "";
            }
          })(),
        ),
        TextCellValue(
          (() {
            try {
              return users
                  .firstWhere((e) =>
              e.branchName == u.branchName &&
                  e.departmentName == "Team Leader")
                  .userid;
            } catch (e) {
              return "";
            }
          })(),
        ),
        TextCellValue(
          (() {
            try {
              return users
                  .firstWhere((e) =>
              e.branchName == u.branchName &&
                  e.departmentName == "Team Leader")
                  .fullName;
            } catch (e) {
              return "";
            }
          })(),
        ),
        TextCellValue(u.imeiNo ?? ""),
        TextCellValue(u.departmentName ?? ""),
        TextCellValue(u.status ?? ""),

        // TextCellValue(u.fullAddress ?? ""),
        // TextCellValue(u.pinCode ?? ""),
        // TextCellValue(u.branchDistance ?? ""),
        // TextCellValue(u.branchLat ?? ""),
        // TextCellValue(u.branchLong ?? ""),

        // TextCellValue(convertTo12Hour(u.shiftStart ?? "")),
        // TextCellValue(convertTo12Hour(u.shiftEnd ?? "")),

        // TextCellValue(u.lastworkingdate),

        //TextCellValue(u.role ?? ""),

      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final fileName =
        "USERS_DETAILS_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    if (kIsWeb) {
      // 🌐 WEB DOWNLOAD
      final content = base64Encode(fileBytes);
      final anchor = html.AnchorElement(
        href:
        "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content",
      )
        ..setAttribute("download", fileName)
        ..click();

      Get.snackbar("Success", "Downloading Excel file...");
    } else {
      // 📱 ANDROID / IOS DOWNLOAD

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";

      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "USERS Report",
      );
    }
  }
  String convertTo12Hour(String time24) {
    try {
      final format24 = DateFormat("HH:mm"); // input format
      final format12 = DateFormat("hh:mm a"); // output format

      final dateTime = format24.parse(time24);
      return format12.format(dateTime);
    } catch (e) {
      return time24; // agar error aaye to original return
    }
  }
  void deleteUser(UserModel user) {
    print("Delete userId: ${user.uid}");
    print("Delete userName: ${user.fullName}");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete User"),
          content: Text("Are you sure you want to delete ${user.fullName}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ❌ cancel
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await callDeleteApi(user.uid); // ✅ API call
              },
              child: Text("Delete"),
            ),

          ],
        );
      },
    );
  }
  Future<void> callDeleteApi(String uid) async {
    try {
      final url = Uri.parse(
          "http://15.206.209.30/attendance/delete_user.php");

      final response = await http.post(
        url,
        body: {
          "uid": uid,
        },
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );
          setState(() {
            loadUsers();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Delete failed")),
          );
        }
      }
    } catch (e) {
      print("Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Set<String> selectedBranches = {};
  List<UserModel> filteredUsers = [];
  List<String> branchList = [];

  void applyBranchFilter() {
    setState(() {
      currentPage = 0; // reset page

      if (selectedBranches.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((u) => selectedBranches.contains(u.branchName))
            .toList();
      }
    });
  }
  void showBranchFilter() {
    Set<String> tempSelected = Set.from(selectedBranches);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Filter by Branch"),
              content: SizedBox(
                width: 300,
                height: 400,
                child: ListView(
                  children: branchList.map((branch) {
                    return CheckboxListTile(
                      title: Text(branch),
                      value: tempSelected.contains(branch),
                      onChanged: (val) {
                        setStateDialog(() {   // ✅ IMPORTANT FIX
                          if (val == true) {
                            tempSelected.add(branch);
                          } else {
                            tempSelected.remove(branch);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    selectedBranches.clear();
                    applyBranchFilter();
                    Navigator.pop(context);
                  },
                  child: const Text("Clear"),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedBranches = tempSelected;
                    applyBranchFilter();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  int currentPage = 0;
  int rowsPerPage = 10;

  List<UserModel> get paginatedUsers {
    final start = currentPage * rowsPerPage;
    final end = start + rowsPerPage;

    return filteredUsers.sublist(
      start,
      end > filteredUsers.length ? filteredUsers.length : end,
    );
  }
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // 🔥 full screen
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // 🔍 Zoomable image
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),

              // ❌ Close button
              Positioned(
                top: 30,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          title: const Text("Employee Management- (Active Employee)",style: TextStyle(color: Colors.white),),
      actions: [
        ElevatedButton(onPressed: (){
          Get.to(()=>InactiveUserScreen(cid: widget.cid,));
        }, style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Perfect square corners
          ),
        ),child: Text("All Employees")),
        SizedBox(
          width: 10,
        ),
        ElevatedButton(onPressed: (){
          Get.to(()=>AddUserScreen(cid:widget.cid));
        }, style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Perfect square corners
          ),
        ),child: Text("Create Employee")),
        SizedBox(width: 10,),
        IconButton(onPressed: (){
          //download the excel file
          downloadExcel();
        }, icon:Icon(Icons.download,color: Colors.white,)),
        SizedBox(width: 10,)
      ],),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        child: Column(
          children: [
            SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey.shade300,
                              ),
                              border: TableBorder.all(
                                color: Colors.black54,
                                width: 1,
                              ),
                              columns:  [
                                DataColumn(label: Text("Action",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                //DataColumn(label: Text("UID")),
                                DataColumn(label: Text("Create Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                //DataColumn(label: Text("Updated Date")),
                                DataColumn(label: Text("City Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("UserID",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Password",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Full Name"
                                  ,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),
                                )),
                            DataColumn(
                              label: Row(
                                children: [
                                  const Text("Office Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                  IconButton(
                                    icon: Icon(
                                      Icons.filter_list,
                                      size: 18,
                                      color: selectedBranches.isNotEmpty
                                          ?  Color(0xff2563EB)
                                          : Colors.grey,
                                    ),
                                    onPressed: showBranchFilter,
                                  ),
                                ],
                              ),
                            ),
                                DataColumn(label: Text("Status",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),

                                DataColumn(label: Text("Image",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("IMEI",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Email",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Phone",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Gender",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),

                                DataColumn(label: Text("State Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Address",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Pin Code",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Distance",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Lat",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Long",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Reporting Position Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Reporting Manager Id",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Reporting Manager Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("User Type",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                // DataColumn(label: Text("Shift Start")),
                                // DataColumn(label: Text("Shift End")),
                                DataColumn(label: Text("Joining Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                               // DataColumn(label: Text("Last Working Date")),

                               // DataColumn(label: Text("Role")),

                              ],
                              rows: paginatedUsers.map((u) {
                                DateTime dt = DateTime.parse(u.createdAt);
                                String formattedDate = DateFormat('dd MMM yyyy').format(dt);
                                String formattedTime = DateFormat('hh:mm a').format(dt);
                                DateTime udt = DateTime.parse(u.updatedAt);
                                String formattedDateU = DateFormat('dd MMM yyyy').format(udt);
                                String formattedTimeU = DateFormat('hh:mm a').format(udt);
                                return DataRow(cells: [
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color:  Color(0xff2563EB)),
                                        onPressed: () => editUser(u),
                                      ),
                                      // IconButton(
                                      //   icon: const Icon(Icons.delete, color: Colors.red),
                                      //   onPressed: () => deleteUser(u),
                                      // ),
                                    ],
                                  )),
                                  //DataCell(Text(u.uid)),
                                 // DataCell(Text(u.cid)),
                                  DataCell(Row(
                                    children: [
                                      Text(formattedDate),
                                      Text(' - '),
                                      Text(formattedTime)
                                    ],
                                  )),
                                  // DataCell(Row(
                                  //   children: [
                                  //     Text(formattedDateU),
                                  //     Text(' - '),
                                  //     Text(formattedTimeU)
                                  //   ],
                                  // )),
                                  DataCell(Text(u.cityName)),
                                  DataCell(Text(u.userid)),
                                  DataCell(Text(u.password)),
                                  DataCell(Row(
                                    children: [
                                      Text(u.fullName),
                                      Text(u.lastName),
                                    ],
                                  )),
                                  DataCell(Text(u.branchName)),
                                  DataCell(Text(
                                    u.status,
                                    style: TextStyle(
                                      color: u.status.toLowerCase() == 'active'
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold
                                    ),
                                  )),

                                  //DataCell(Text(u.userToken)),
                                  DataCell(
                                    GestureDetector(
                                      onTap: () {
                                        _showImageDialog(
                                          context,
                                          u.userImg,
                                        );
                                      },
                                      child: u.userImg != null &&
                                          u.userImg.toString().isNotEmpty
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          u.userImg,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                        ),
                                      )
                                          : const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                  DataCell(Text(u.imeiNo)),

                                  DataCell(Text(u.userEmail)),
                                  DataCell(Text(u.userPhone)),
                                  DataCell(Text(u.gender)),

                                  DataCell(Text(u.districtName)),
                                  DataCell(Text(u.fullAddress)),
                                  DataCell(Text(u.pinCode)),
                                  //DataCell(Text(u.branchId)),
                                  DataCell(Text(u.branchDistance)),
                                  DataCell(Text(u.branchLat)),
                                  DataCell(Text(u.branchLong)),
                                  DataCell(
                                    Text(
                                      (() {
                                        try {
                                          final tl = users.firstWhere(
                                                (e) =>
                                            e.branchName == u.branchName &&
                                                e.departmentName == "Team Leader",
                                          );
                                          return "Reporting Manager (${tl.branchName})";
                                        } catch (e) {
                                          return "";
                                        }
                                      })(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (() {
                                        try {
                                          return users
                                              .firstWhere((e) =>
                                          e.branchName == u.branchName &&
                                              e.departmentName == "Team Leader")
                                              .userid;
                                        } catch (e) {
                                          return "";
                                        }
                                      })(),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (() {
                                        try {
                                          return users
                                              .firstWhere((e) =>
                                          e.branchName == u.branchName &&
                                              e.departmentName == "Team Leader")
                                              .fullName;
                                        } catch (e) {
                                          return "";
                                        }
                                      })(),
                                    ),
                                  ),
                                  DataCell(Text(u.departmentName)),
                                  //DataCell(Text(u.shiftId)),
                                  // DataCell(Text(convertTo12Hour(u.shiftStart))),
                                  // DataCell(Text(convertTo12Hour(u.shiftEnd))),
                                  DataCell(Text(u.dateOfJoining)),
                                  //DataCell(Text(u.lastworkingdate)),

                                  //DataCell(Text(u.role)),


                                ]);
                              }).toList(),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 0
                        ? () {
                      setState(() => currentPage--);
                    }
                        : null,
                    child: const Text("Previous"),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Page ${currentPage + 1} of ${(filteredUsers.length / rowsPerPage).ceil()}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed:
                    (currentPage + 1) * rowsPerPage < filteredUsers.length
                        ? () {
                      setState(() => currentPage++);
                    }
                        : null,
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
}
