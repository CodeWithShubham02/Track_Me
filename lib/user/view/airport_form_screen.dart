import 'dart:io';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';

import '../../admin/model/user_model.dart';
import '../../handller/encription_decription.dart';
import '../airport_form_model.dart';
import '../controller/airport_form_controller.dart';

class AirportFormScreen extends StatefulWidget {
  final UserModel userModel;

  const AirportFormScreen({super.key, required this.userModel});

  @override
  State<AirportFormScreen> createState() => _AirportFormScreenState();
}

class _AirportFormScreenState extends State<AirportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? relation;
  String? variant;
  String? status;

  final TextEditingController remarksController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController applicationController = TextEditingController();




  final ImagePicker _picker = ImagePicker();

  final List<String> relationList = ["ETB", "NTB"];
  final List<String> variantList = ["Platinum", "Signature"];
  final List<String> statusList = ["Rejected", "Review", "Partial", "Carded"];

  @override
  void initState() {
    super.initState();
  }

  Future<String> getLatLngString() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      print("Error getting lat/lng: $e");
      return "0.0,0.0";
    }
  }

  // ✅ Multiple Images List
  List<File> mobileImages = [];
  List<Uint8List> webImages = [];

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 70,preferredCameraDevice: CameraDevice.rear,);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          webImages.add(bytes);
        });
      } else {
        setState(() {
          mobileImages.add(File(image.path));
        });
      }
    }
  }
  Future<List<String>> uploadAllImages() async {
    List<Future<String>> uploadTasks = [];

    if (kIsWeb) {
      for (int i = 0; i < webImages.length; i++) {
        String objectKey =
            "airport_forms/${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

        uploadTasks.add(
          uploadImageToS3(
            imageBytes: webImages[i],
            bucket: "joizone-s3",
            objectKey: objectKey,
          ),
        );
      }
    } else {
      for (int i = 0; i < mobileImages.length; i++) {
        Uint8List bytes = await mobileImages[i].readAsBytes();

        String objectKey =
            "airport_forms/${DateTime.now().millisecondsSinceEpoch}_$i.jpg";

        uploadTasks.add(
          uploadImageToS3(
            imageBytes: bytes,
            bucket: "joizone-s3",
            objectKey: objectKey,
          ),
        );
      }
    }

    return await Future.wait(uploadTasks);
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

  void submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if ((kIsWeb && webImages.isEmpty) ||
        (!kIsWeb && mobileImages.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please capture images")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String latLng = await getLatLngString();

      List<String> uploadedImageUrls = await uploadAllImages();

      final model = AirportFormModel(
        uid: widget.userModel.uid,
        cid: widget.userModel.cid,
        userId: widget.userModel.userid,
        userName: widget.userModel.fullName,
        cityName: widget.userModel.branchName,
        applicationNo: applicationController.text,
        relation: relation!,
        variant: variant!,
        status: status!,
        remarks: remarksController.text,
        contactNo: contactController.text,
        gpsLocation: latLng,
        kioskName: widget.userModel.branchName,
        imageUrls: uploadedImageUrls,
      );

      bool success = await AirportFormController.submitForm(model);

      Navigator.pop(context); // close loader

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Form submitted successfully")),
        );

        _formKey.currentState!.reset();

        setState(() {
          mobileImages.clear();
          webImages.clear();
          relation = null;
          variant = null;
          status = null;
        });
        Get.back();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit form")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        backgroundColor: Colors.blue,
        title: const Text("Client Form",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,fontFamily: 'impact'),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: applicationController,
                decoration: const InputDecoration(
                  hint: Row(
                    children: [
                      Text("Application Number "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9 ]'), // Only letters, numbers & space
                  ),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Application number required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: relation,
                decoration: const InputDecoration(

                  hint: Row(
                    children: [
                      Text("Relation "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
                items: relationList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => relation = val),
                validator: (val) => val == null ? "Select relation" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: variant,
                decoration: const InputDecoration(

                  hint: Row(
                    children: [
                      Text("Variant "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
                items: variantList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => variant = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(

                  hint: Row(
                    children: [
                      Text("Status "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
                items: statusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => status = val),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: "Remarks",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9 ]'), // Only letters, numbers & space
                  ),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Enter remarks";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(
                  hint: Row(
                    children: [
                      Text("Phone "),
                      Text("*",style: TextStyle(color: Colors.red),),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9 ]'), // Only letters, numbers & space
                  ),
                ],
                validator: (val) =>
                val!.length != 10 ? "Enter valid number" : null,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Captured Images",
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                kIsWeb ? webImages.length : mobileImages.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: kIsWeb
                            ? Image.memory(webImages[index],
                            fit: BoxFit.cover)
                            : Image.file(mobileImages[index],
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (kIsWeb) {
                                webImages.removeAt(index);
                              } else {
                                mobileImages.removeAt(index);
                              }
                            });
                          },
                          child: Container(
                            color: Colors.red,
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              /// Capture Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: pickImage,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Image"),
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: submitForm,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 40),
          SizedBox(height: 8),
          Text("Capture Image"),
        ],
      ),
    );
  }
}
