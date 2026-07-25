import 'dart:convert';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../handller/encription_decription.dart';

class DynamicUserFormScreen extends StatefulWidget {
  final String templateId;
  final String formName;
  final String branchName;
  final String uid;
  final String cid;

  const DynamicUserFormScreen({
    super.key,
    required this.templateId,
    required this.formName,
    required this.branchName,
    required this.uid,
    required this.cid,
  });

  @override
  State<DynamicUserFormScreen> createState() =>
      _DynamicUserFormScreenState();
}

class _DynamicUserFormScreenState
    extends State<DynamicUserFormScreen> {

  bool loading = true;

  List<dynamic> fields = [];

  Map<String, dynamic> formData = {};

  @override
  void initState() {
    super.initState();
    getFields();
  }

  Future<void> getFields() async {

    try {

      final response = await http.get(

        Uri.parse(
          "http://15.206.209.30/attendance/get_fields.php?template_id=${widget.templateId}",
        ),

      );

      if (response.statusCode == 200) {

        final json = jsonDecode(response.body);

        if (json["status"] == true) {

          fields = json["data"];

        }

      }

    } catch (e) {

      debugPrint(e.toString());

    }

    loading = false;

    setState(() {});
  }
  final ImagePicker picker = ImagePicker();

  Map<String, File?> imageFiles = {};

  Future<void> pickImage(String fieldName) async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    File file = File(image.path);

    setState(() {
      imageFiles[fieldName] = file;
    });

    try {
      Uint8List bytes = (await file.readAsBytes());

      String objectKey =
          "dynamic_forms/${widget.templateId}/$fieldName/${DateTime.now().millisecondsSinceEpoch}.jpg";

      String imageUrl = await uploadImageToS3(
        imageBytes: bytes,
        bucket: "joizone-s3",
        objectKey: objectKey,
      );

      /// Save URL in formData
      formData[fieldName] = imageUrl;

      debugPrint("Uploaded Image URL : $imageUrl");
    } catch (e) {
      debugPrint("Upload Error : $e");
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.blue,
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
        title:  Text(widget.formName, style: TextStyle(fontSize: 18,color: Colors.white)),
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(

        padding: const EdgeInsets.all(15),

        itemCount: fields.length + 1,

        itemBuilder: (context, index) {

          if (index == fields.length) {

            return ElevatedButton(

              onPressed: submitForm,

              child: const Text("Submit"),

            );
          }

          return buildField(fields[index]);

        },

      ),
    );
  }
  Future<void> submitForm() async {

    List<Map<String,dynamic>> values=[];

    for(var field in fields){

      values.add({

        "field_id":field["id"],

        "value":formData[field["field_name"]]??""

      });

    }

    var response=await http.post(

      Uri.parse(
        "http://15.206.209.30/attendance/submit_dynamic_form.php",
      ),

      body:{

        "template_id":widget.templateId,

        "uid":widget.uid, // login user uid

        "cid":widget.cid, // login user cid

        "branch_name":widget.branchName,

        "form_data":jsonEncode(values),

      },

    );

    final json=jsonDecode(response.body);

    if(json["status"]){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(

          content: Text("Form Submitted Successfully"),

        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back(result: true);
      });

    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(json["message"] ?? "Submission Failed"),
        ),
      );
    }

  }
  Widget buildField(dynamic field) {

    switch (field["field_type"]) {

      case "text":

        return Padding(

          padding: const EdgeInsets.only(bottom: 15),

          child: TextFormField(

            decoration: InputDecoration(

              labelText: field["field_label"],

              border: const OutlineInputBorder(),

            ),

            onChanged: (v) {

              formData[field["field_name"]] = v;

            },

          ),

        );

      case "number":

        return Padding(

          padding: const EdgeInsets.only(bottom: 15),

          child: TextFormField(

            keyboardType: TextInputType.number,

            decoration: InputDecoration(

              labelText: field["field_label"],

              border: const OutlineInputBorder(),

            ),

            onChanged: (v) {

              formData[field["field_name"]] = v;

            },

          ),

        );

      case "dropdown":

        List options = field["options"];

        return Padding(

          padding: const EdgeInsets.only(bottom: 15),

          child: DropdownButtonFormField(

            decoration: InputDecoration(

              labelText: field["field_label"],

              border: const OutlineInputBorder(),

            ),

            items: options.map((e) {

              return DropdownMenuItem(

                value: e,

                child: Text(e),

              );

            }).toList(),

            onChanged: (v) {

              formData[field["field_name"]] = v;

            },

          ),

        );

      case "image":

        return Padding(

          padding: const EdgeInsets.only(bottom: 20),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                field["field_label"],

                style: const TextStyle(

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(height: 10),

              Row(

                children: [

                  InkWell(

                    onTap: () {

                      pickImage(field["field_name"]);

                    },

                    child: Container(

                      width: 70,

                      height: 70,

                      decoration: BoxDecoration(

                        color: Colors.grey.shade200,

                        borderRadius: BorderRadius.circular(10),

                        border: Border.all(color: Colors.grey),

                      ),

                      child: const Icon(

                        Icons.camera_alt,

                        size: 35,

                        color: Colors.blue,

                      ),

                    ),

                  ),

                  const SizedBox(width: 15),

                  if(imageFiles[field["field_name"]] != null)

                    ClipRRect(

                      borderRadius: BorderRadius.circular(10),

                      child: Image.file(

                        imageFiles[field["field_name"]]!,

                        width: 90,

                        height: 90,

                        fit: BoxFit.cover,

                      ),

                    ),

                ],

              ),

            ],

          ),

        );

      default:

        return Padding(

          padding: const EdgeInsets.only(bottom: 15),

          child: TextFormField(

            decoration: InputDecoration(

              labelText: field["field_label"],

              border: const OutlineInputBorder(),

            ),

            onChanged: (v) {

              formData[field["field_name"]] = v;

            },

          ),

        );

    }
  }
}