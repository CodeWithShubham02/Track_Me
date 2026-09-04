import 'dart:convert';
import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/controller/department_controller.dart';
import 'package:joizone/admin/controller/shift_controller.dart';
import 'package:joizone/admin/model/department_model.dart';
import 'package:joizone/admin/model/shift_model.dart';

import '../../handller/encription_decription.dart';
import '../controller/branch_controller.dart';
import '../controller/user_controller.dart';
import '../model/branch_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddUserScreen extends StatefulWidget {
  final String cid;
  const AddUserScreen({super.key, required this.cid});
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final UserController controller = UserController();

  final useridCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  // ----------------------------
  final lastNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final cityNameCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  final districtNameCtrl = TextEditingController();
  final reportingPositionCtrl = TextEditingController();
  // -------------------------------
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final fullAddressCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  String? selectedGender;
  bool loading = false;

  final UserController _controller1 = UserController();
  DateTime? selectedDate;
  TextEditingController dateController = TextEditingController();
  Future<void> submitUser() async {
    if (useridCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty ||
        nameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        districtNameCtrl.text.isEmpty ||
        pinCodeCtrl.text.isEmpty ||
        cityNameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        selectedBranches.isEmpty ||
        selectedShiftId == null ||
        selectedDepartId == null ||
        selectedGender == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Please fill all required fields",
          ),
        ),
      );

      return;
    }
    print("date of joing ${dateController.text}");
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Date of Joining")),
      );
      return;
    }

    //String apiDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    // ✅ API format (yyyy-MM-dd)
    String apiDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final success = await _controller1.createUser(
      cid: widget.cid,
      userid: useridCtrl.text,
      password: passwordCtrl.text,
      userToken: "",
      userImg: photoUrl ?? "",
      fullName: nameCtrl.text,
      userEmail: emailCtrl.text,
      userPhone: phoneCtrl.text,
      gender: genderCtrl.text,
      fullAddress: fullAddressCtrl.text,
      branchId: selectedBranchId ?? "",
      branchName: selectedBranchName ?? "",
      branchDistance: selectedBranchDistance ?? "",
      branchLat: selectedBranchLat ?? "",
      branchLong: selectedBranchLong ?? "",
      branchIds: selectedBranchIds,
      departmentId: selectedDepartId ?? "",
      departmentName: selectedDepartName ?? "",
      shiftId: selectedShiftId ?? "",
      shiftStart: selectedShiftStart ?? "",
      shiftEnd: selectedShiftEnd ?? "",
      dateOfJoining: apiDate, // DD-MM-YYYY or YYYY-MM-DD
      imeiNo: "",
      middleName: middleNameCtrl.text,
      lastName: lastNameCtrl.text,
      cityName: cityNameCtrl.text,
      districtName: districtNameCtrl.text,
      pinCodeName: pinCodeCtrl.text,
    );
    print("date of joing $dateController");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success["message"]),
        backgroundColor: success["status"] ? Colors.green : Colors.red,
      ),
    );

    if (success["status"] == true) {
      Get.back();
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;

        // ✅ UI format (dd-MM-yyyy)
        dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  //branch
  final BranchController _controller = BranchController();
  List<BranchModel> branchList = [];
  // ============================================================
// MULTIPLE BRANCH
// ============================================================

  List<BranchModel> selectedBranches = [];

  List<String> selectedBranchIds = [];

  String? selectedBranchId;
  String? selectedBranchName;
  String? selectedBranchLat;
  String? selectedBranchLong;
  String? selectedBranchDistance;
  bool isLoading = false;

  //shift
  final ShiftController _shiftController = ShiftController();
  List<ShiftModel> shiftList = [];
  String? selectedShiftId;
  String? selectedShiftStart;
  String? selectedShiftEnd;
  bool isShiftLoading = false;

  //department
  final DepartmentController _departmentController = DepartmentController();
  List<DepartmentModel> departmentList = [];
  String? selectedDepartId;
  String? selectedDepartName;
  bool isDepartLoading = false;

  //photo
  bool isLoadingPhoto = false;
  File? photo; // Mobile
  Uint8List? webPhoto; // Web
  String? photoUrl; // Uploaded URL

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
    loadBranches();
    loadShift();
    loadDepartment();

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

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImagePhoto1(ImageSource source) async {
    try {
      setState(() => isLoadingPhoto = true);

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (picked == null) {
        return null;
      }

      final Uint8List bytes = await picked.readAsBytes();

      // Preview
      if (!kIsWeb) {
        photo = File(picked.path);
      } else {
        webPhoto = bytes;
      }

      setState(() {});

      // Upload through PHP
      final imageUrl = await uploadImageToServer(bytes);

      if (imageUrl != null) {
        setState(() {
          photoUrl = imageUrl;
        });
      }

      return imageUrl;

    } catch (e) {
      debugPrint("❌ Pick/Upload error: $e");
      return null;

    } finally {
      if (mounted) {
        setState(() {
          isLoadingPhoto = false;
        });
      }
    }
  }

  Future<String?> uploadImageToServer(Uint8List bytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://15.206.209.30/attendance/upload_image.php',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename:
          'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      debugPrint("Upload Status: ${response.statusCode}");
      debugPrint("Upload Response: $responseBody");

      if (response.statusCode != 200) {
        throw Exception("Upload failed");
      }

      final data = jsonDecode(responseBody);

      if (data['status'] == true) {
        return data['url'];
      }

      throw Exception(data['message'] ?? "Upload failed");

    } catch (e) {
      debugPrint("❌ Upload error: $e");
      return null;
    }
  }
  void deletePhoto() {
    setState(() {
      photo = null;
      webPhoto = null;
      photoUrl = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Photo deleted")));
  }

  Future<void> loadBranches() async {
    final list = await _controller.getBranches(widget.cid); // cid = 1

    setState(() {
      branchList = list;
      isLoading = false;
    });
  }

  Future<void> loadShift() async {
    final list = await _shiftController.fetchShifts(widget.cid);
    setState(() {
      shiftList = list;
      isShiftLoading = false;
    });
  }

  Future<void> loadDepartment() async {
    final list = await _departmentController.fetchDepartments(widget.cid);
    setState(() {
      departmentList = list;
      isDepartLoading = false;
    });
  }
  Future<void> selectMultipleBranches() async {
    List<BranchModel> tempSelected = List.from(selectedBranches);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Select Branches",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SizedBox(
                width: 450,
                height: 450,

                child: Column(
                  children: [

                    // =================================================
                    // SELECT ALL
                    // =================================================

                    CheckboxListTile(
                      title: const Text(
                        "Select All",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      value: tempSelected.length == branchList.length &&
                          branchList.isNotEmpty,

                      onChanged: (value) {

                        setDialogState(() {

                          if (value == true) {

                            tempSelected = List.from(branchList);

                          } else {

                            tempSelected.clear();
                          }

                        });

                      },
                    ),

                    const Divider(),

                    // =================================================
                    // BRANCH LIST
                    // =================================================

                    Expanded(
                      child: ListView.builder(
                        itemCount: branchList.length,

                        itemBuilder: (context, index) {

                          final branch = branchList[index];

                          final isSelected = tempSelected.any(
                                (b) => b.id == branch.id,
                          );

                          return CheckboxListTile(
                            title: Text(
                              branch.branchName,
                            ),

                            subtitle: Text(
                              "ID: ${branch.id}",
                            ),

                            value: isSelected,

                            onChanged: (value) {

                              setDialogState(() {

                                if (value == true) {

                                  if (!tempSelected.any(
                                        (b) => b.id == branch.id,
                                  )) {
                                    tempSelected.add(branch);
                                  }

                                } else {

                                  tempSelected.removeWhere(
                                        (b) => b.id == branch.id,
                                  );

                                }

                              });

                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              actions: [

                // =================================================
                // CLEAR
                // =================================================

                TextButton(
                  onPressed: () {

                    setDialogState(() {
                      tempSelected.clear();
                    });

                  },

                  child: const Text(
                    "Clear",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),

                // =================================================
                // CANCEL
                // =================================================

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),
                ),

                // =================================================
                // APPLY
                // =================================================

                ElevatedButton(
                  onPressed: () {

                    if (tempSelected.isEmpty) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select at least one branch",
                          ),
                        ),
                      );

                      return;
                    }

                    setState(() {

                      selectedBranches = List.from(tempSelected);

                      // ---------------------------------------------
                      // First branch = existing users table branch
                      // ---------------------------------------------

                      final firstBranch = selectedBranches.first;

                      selectedBranchId = firstBranch.id;

                      selectedBranchName = firstBranch.branchName;

                      selectedBranchLat = firstBranch.lat;

                      selectedBranchLong = firstBranch.long;

                      selectedBranchDistance = firstBranch.distance;

                      // ---------------------------------------------
                      // All branch IDs
                      // ---------------------------------------------

                      selectedBranchIds = selectedBranches
                          .map((branch) => branch.id)
                          .toList();

                    });

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
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    photoUrl = null;
  }

  bool isPasswordVisible = false;

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
        title: const Text(
          "Create New Employee",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔥 ROW (3 FIELDS)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: useridCtrl,
                      decoration: const InputDecoration(
                        labelText: "User Id *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: passwordCtrl,

                      // 👇 IMPORTANT
                      obscureText: !isPasswordVisible,

                      decoration: InputDecoration(
                        labelText: "Password *",
                        border: const OutlineInputBorder(),

                        // 👁️ Eye icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "First Name *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: middleNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Middle Name *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: lastNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Last Name *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [

                /// PHONE
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                /// GENDER
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                          genderCtrl.text = value ?? "";
                        });
                      },
                    ),
                  ),
                ),

                /// DATE OF JOINING
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () => selectDate(context),
                      decoration: const InputDecoration(
                        labelText: "Date of Joining",
                        hintText: "DD-MM-YYYY",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today,color:  Color(0xff2563EB),),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [

                /// BRANCH
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () async {
                        await selectMultipleBranches();
                      },

                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Select Branches *",
                          border: OutlineInputBorder(),
                        ),

                        child: Row(
                          children: [

                            Expanded(
                              child: selectedBranches.isEmpty
                                  ? const Text(
                                "Select Branches",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              )
                                  : Text(
                                selectedBranches
                                    .map((branch) => branch.branchName)
                                    .join(", "),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const Icon(
                              Icons.arrow_drop_down,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                /// SHIFT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isShiftLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      value: selectedShiftId,
                      hint: const Text("Select Shift *"),
                      items: shiftList.map((shift) {
                        return DropdownMenuItem<String>(
                          value: shift.shiftId,
                          child: Text(
                            "${shift.shiftStart} - ${shift.shiftEnd}",
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final shift =
                        shiftList.firstWhere((b) => b.shiftId == value);
                        setState(() {
                          selectedShiftId = shift.shiftId;
                          selectedShiftStart = shift.shiftStart;
                          selectedShiftEnd = shift.shiftEnd;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                /// DEPARTMENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isDepartLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      value: selectedDepartId,
                      hint: const Text("Select User Type *"),
                      items: departmentList.map((depart) {
                        return DropdownMenuItem(
                          value: depart.id,
                          child: Text(depart.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final department =
                        departmentList.firstWhere((b) => b.id == value);
                        setState(() {
                          selectedDepartId = department.id;
                          selectedDepartName = department.name;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                /// DISTRICT NAME
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownSearch<String>(
                      items: states,
                      selectedItem: selectedState,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "State Name *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                          districtNameCtrl.text = value ?? "";
                        });
                      },
                    )
                  ),
                ),
                /// CITY NAME
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownSearch<String>(
                        items: cities,
                        selectedItem: selectedCities,
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "City Name *",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedCities = value;
                            cityNameCtrl.text = value ?? "";
                          });
                        },
                      )
                  ),
                ),


                /// FULL ADDRESS
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: fullAddressCtrl,
                      decoration: const InputDecoration(
                        labelText: "Full Address",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child:Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: pinCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Pin Code *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      value: selectedBranchId,
                      hint: const Text("Reporting Position"),
                      items: branchList.map((branch) {
                        return DropdownMenuItem<String>(
                          value: branch.id,
                          child: Text("Reporting Position : ${branch.branchName}"),
                        );
                      }).toList(),

                      // ✅ ONLY SELECT, NO EXTRA LOGIC
                      onChanged: (value) {

                      },

                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                )
              ],
            ),


            /// IMAGE PICKER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(color: Colors.black),
                ),
                child: Center(
                  child: isLoadingPhoto
                      ? const CircularProgressIndicator()
                      : photo == null
                      ? InkWell(
                          onTap: () async {
                            final imageUrl = await pickImagePhoto1(
                              ImageSource.gallery,
                            );
                            print("Uploaded Image URL: $imageUrl");
                          },
                          child: const Text(
                            "Select Image",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        )
                      : Image.file(photo!, fit: BoxFit.cover),
                ),
              ),
            ),

            /// BUTTON
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: loading ? null : submitUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xff2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Perfect square corners
                  ),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add Employee"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
