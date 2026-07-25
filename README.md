# joizone

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



https://www.wix.com/website-template/view/html/1757?originUrl=https%3A%2F%2Fwww.wix.com%2Fwebsite%2Ftemplates%2Fhtml%2Fbusiness%2Ffinance%2F2&tpClick=view_button&esi=1e7c21e8-4eac-402c-8b45-28b574f762ce
##//jab user punch in punch out kare to uska recorde es table me store ho and
##INSERT INTO `attendance_logs`(`id`, `attendance_id`, `uid`, `cid`, `punch_type`, `punch_time`, `lat`, `lng`, `remark`, `image`, `created_at`) VALUES ('[value-1]','[value-2]','[value-3]','[value-4]','[value-5]','[value-6]','[value-7]','[value-8]','[value-9]','[value-10]','[value-11]')

#//esme user current value colulate karke store kare table me
#INSERT INTO `attendance`(`id`, `cid`, `uid`, `name`, `department`, `office_name`, `status`, `distance`, `shift_start`, `shift_end`, `punch_in_time`, `punch_in_lat`, `punch_in_lng`, `punch_in_remark`, `punch_in_image`, `punch_out_time`, `punch_out_lat`, `punch_out_lng`, `punch_out_remark`, `punch_out_image`, `total_break_minutes`, `working_minutes`, `net_working_hours`, `created_at`) VALUES ('[value-1]','[value-2]','[value-3]','[value-4]','[value-5]','[value-6]','[value-7]','[value-8]','[value-9]','[value-10]','[value-11]','[value-12]','[value-13]','[value-14]','[value-15]','[value-16]','[value-17]','[value-18]','[value-19]','[value-20]','[value-21]','[value-22]','[value-23]','[value-24]')


import 'dart:core';
import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:aws_s3_upload/aws_s3_upload.dart';
import 'package:flutter/material.dart';
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

class AddUserScreen extends StatefulWidget {
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
final genderCtrl=TextEditingController();
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
selectedBranchId == null ||
selectedShiftId == null ||
selectedDepartId == null ||
selectedGender == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all required fields")),
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
      cid: "1",
      userid: useridCtrl.text,
      password: passwordCtrl.text,
      userToken: "token_123",
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
      districtName:districtNameCtrl.text,
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
        dateController.text =
            DateFormat('dd-MM-yyyy').format(picked);
      });
    }
}
//branch
final BranchController _controller = BranchController();
List<BranchModel> branchList = [];
String? selectedBranchId;
String? selectedBranchName;
String? selectedBranchLat;
String? selectedBranchLong;
String? selectedBranchDistance;
bool isLoading = false;

//shift
final ShiftController _shiftController=ShiftController();
List<ShiftModel> shiftList=[];
String? selectedShiftId;
String? selectedShiftStart;
String? selectedShiftEnd;
bool isShiftLoading = false;

//department
final DepartmentController _departmentController=DepartmentController();
List<DepartmentModel> departmentList=[];
String? selectedDepartId;
String? selectedDepartName;
bool isDepartLoading=false;

//photo
bool isLoadingPhoto = false;
File? photo;          // Mobile
Uint8List? webPhoto; // Web
String? photoUrl;     // Uploaded URL



@override
void initState() {
// TODO: implement initState
super.initState();
loadBranches();
loadShift();
loadDepartment();
}
final ImagePicker _picker = ImagePicker();

Future<String?> pickImagePhoto1(ImageSource source) async {
try {
setState(() => isLoadingPhoto = true);

      final XFile? picked =
      await _picker.pickImage(source: source, imageQuality: 80);

      if (picked == null) {
        setState(() => isLoadingPhoto = false);
        return null;
      }

      final Uint8List bytes = await picked.readAsBytes();

      // 👇 local preview ke liye
      if (!kIsWeb) {
        photo = File(picked.path);
      } else {
        webPhoto = bytes;
      }

      setState(() {}); // preview refresh

      final fileName =
          "uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final imageUrl = await uploadImageToS3(
        imageBytes: bytes,
        bucket: "joizone-s3",
        objectKey: fileName,
      );

      photoUrl = imageUrl; // ✅ save public URL
      return imageUrl;
    } catch (e) {
      print("❌ Pick/Upload error: $e");
      return null;
    } finally {
      setState(() => isLoadingPhoto = false);
    }
}

Future<String> uploadImageToS3({
required Uint8List imageBytes,
required String bucket,
required String objectKey,
String region = 'ap-south-1',
}) async {
final s3 = S3(
region: region,
credentials: AwsClientCredentials(
accessKey: decryptFMS(
"TohPtOvObC8NnBOp/1BM30tSr97U803JZ+gqI3Jf4uM=",
"QWRTEfnfdys635",
),
secretKey: decryptFMS(
"Exz2WIEt2w1JRVZREvtIPeRX5Jti2p2mcHqs7Hh87/47BQidFAUAkLOxlzYFlctw",
"QWRTEfnfdys635",
),
),
);

    await s3.putObject(
      bucket: bucket,
      key: objectKey,
      body: imageBytes,
      contentLength: imageBytes.length,
      contentType: 'image/jpeg',
    );

    return "https://$bucket.s3.$region.amazonaws.com/$objectKey";
}



void deletePhoto() {
setState(() {
photo = null;
webPhoto = null;
photoUrl = null;
});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Photo deleted")),
    );
}

Future<void> loadShift() async{
final list=await _shiftController.fetchShifts("1");
setState(() {
shiftList=list;
isShiftLoading=false;
});
}
Future<void> loadBranches() async {
final list = await _controller.getBranches("1"); // cid = 1

    setState(() {
      branchList = list;
      isLoading = false;
    });
}
Future<void> loadDepartment() async{
final list=await _departmentController.fetchDepartments("1");
setState(() {
departmentList=list;
isDepartLoading=false;
});
}
String convertTo12Hour(String? time24) {
if (time24 == null || time24.isEmpty) return "";

    try {
      final format24 = DateFormat("HH:mm"); // agar HH:mm:ss ho to change karo
      final format12 = DateFormat("hh:mm a");

      return format12.format(format24.parse(time24));
    } catch (e) {
      return time24;
    }
}
@override
void dispose() {
dateController.dispose();
// TODO: implement dispose
super.dispose();
photoUrl = null;


}
bool isPasswordHidden = true;
Widget buildRow(List<Widget> children) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 8),
child: Row(
children: children.map((child) {
return Expanded(
child: Padding(
padding: const EdgeInsets.all(4.0),
child: child,
),
);
}).toList(),
),
);
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
backgroundColor: Colors.blue,
iconTheme: IconThemeData(color: Colors.white),
title: const Text("Create User",style: TextStyle(color: Colors.white,fontSize: 18),)),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(
children: [
buildRow([
TextField(
controller: useridCtrl,
decoration: const InputDecoration(
labelText: "User Id *",
border: OutlineInputBorder(),
),
),
TextField(
controller: passwordCtrl,
obscureText: isPasswordHidden,
decoration: InputDecoration(
labelText: "Password *",
border: const OutlineInputBorder(),
suffixIcon: IconButton(
icon: Icon(
isPasswordHidden
? Icons.visibility_off
: Icons.visibility,
),
onPressed: () {
setState(() {
isPasswordHidden = !isPasswordHidden;
});
},
),
),
),
TextField(
controller: nameCtrl,
decoration: const InputDecoration(
labelText: "First Name *",
border: OutlineInputBorder(),
),
),
]),
buildRow([
TextField(
controller: middleNameCtrl,
decoration: const InputDecoration(
labelText: "Middle Name *",
border: OutlineInputBorder(),
),
),
TextField(
controller: lastNameCtrl,

                decoration: InputDecoration(
                  labelText: "Last Name *",
                  border: const OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: cityNameCtrl,
                decoration: const InputDecoration(
                  labelText: "City Name *",
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            buildRow([
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email *",
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Phone *",
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
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
            ]),
            buildRow([
              DropdownButtonFormField<String>(
                value: selectedShiftId,
                hint: const Text("Select Shift *"),
                items: shiftList.map((shift) {
                  return DropdownMenuItem(
                    value: shift.shiftId,
                    child: Text(
                      "${convertTo12Hour(shift.shiftStart)} - ${convertTo12Hour(shift.shiftEnd)}",
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  final shift = shiftList.firstWhere((b) => b.shiftId == value);
                  setState(() {
                    selectedShiftId = shift.shiftId;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

              DropdownButtonFormField<String>(
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
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedBranchId,
                hint: const Text("Select Kiosk *"),
                items: branchList.map((branch) {
                  return DropdownMenuItem(
                    value: branch.id,
                    child: Text(branch.branchName),
                  );
                }).toList(),
                onChanged: (value) {
                  final branch = branchList.firstWhere((b) => b.id == value);
                  setState(() {
                    selectedBranchId = branch.id;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),

            ]),
            buildRow([
              TextField(
                controller: fullAddressCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Address",
                  border: OutlineInputBorder(),
                ),
              ),
              TextFormField(
                controller: dateController,
                readOnly: true,
                onTap: () => selectDate(context),
                decoration: const InputDecoration(
                  labelText: "Date of Joining",
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedBranchId,
                hint: const Text("Select Reporting Position *"),
                items: branchList.map((branch) {
                  return DropdownMenuItem(
                    value: branch.id,
                    child: Text("Reporting Manager "+branch.branchName),
                  );
                }).toList(),
                onChanged: (value) {
                  final branch = branchList.firstWhere((b) => b.id == value);
                  setState(() {
                    selectedBranchId = branch.id;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            buildRow([
              TextField(
                controller: districtNameCtrl,
                decoration: const InputDecoration(
                  labelText: "District Name *",
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: pinCodeCtrl,
                decoration: InputDecoration(
                  labelText: "Pin Code *",
                  border: const OutlineInputBorder(),
                ),
              ),

            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submitUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 🔥 Punch out color
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create User"),
            )
          ],
        ),
      ),
    );
}
}
