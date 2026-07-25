import 'dart:convert';
import 'dart:typed_data';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/model/user_model.dart';
import '../../handller/encription_decription.dart';

class UserIdCardDialog extends StatefulWidget {
  final UserModel user;

  const UserIdCardDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserIdCardDialog> createState() => _UserIdCardDialogState();
}

class _UserIdCardDialogState extends State<UserIdCardDialog> {
  final ImagePicker _picker = ImagePicker();

  bool isUploading = false;
  String? profileImage;
  @override
  void initState() {
    super.initState();
    profileImage = widget.user.userImg;
    loadUserImg();
  }
  String? userImg;
  void loadUserImg() async{
    final prefs = await SharedPreferences.getInstance();
    final img=prefs.get("userimg");
    userImg=img as String?;
    print("User Pref: $img");
  }
  Future<void> openCamera() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        isUploading = true;
      });

      final Uint8List bytes = await image.readAsBytes();

      final fileName =
          "uploads/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final imageUrl = await uploadImageToS3(
        imageBytes: bytes,
        bucket: "joizone-s3",
        objectKey: fileName,
      );

      print("Image Url: $imageUrl");

      await updateProfileImage(imageUrl);
      final prefs = await SharedPreferences.getInstance();

// userimg update
      await prefs.setString('userimg', imageUrl);

// user_model update
      String? userData = prefs.getString('user_model');

      if (userData != null) {
        Map<String, dynamic> json = jsonDecode(userData);

        json['userImg'] = imageUrl;

        await prefs.setString(
          'user_model',
          jsonEncode(json),
        );
      }

      setState(() {
        profileImage = imageUrl;
        isUploading = false;
      });
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      debugPrint("Camera Error : $e");
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
      contentType: "image/jpeg",
    );

    return "https://$bucket.s3.$region.amazonaws.com/$objectKey";
  }
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/update_user_img.php",
        ),
        body: {
          "uid": widget.user.uid,
          "cid": widget.user.cid,
          "user_img": imageUrl,
        },
      );

      print(response.body);

      final data = jsonDecode(response.body);

      if (data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile image updated successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Header
              const Text(
                "ID CARD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 20),

              /// Profile Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage != null &&
                            profileImage!.isNotEmpty
                            ? NetworkImage(profileImage!)
                            : null,
                        child: profileImage == null ||
                            profileImage!.isEmpty
                            ? const Icon(
                          Icons.person,
                          size: 50,
                        )
                            : null,
                      ),

                      if (isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: openCamera,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "ID : ${widget.user.userid}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        Text(
                          widget.user.role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Divider(
                color: Colors.white,
                thickness: 1,
              ),

              const SizedBox(height: 10),

              infoRow(
                Icons.phone,
                "Mobile",
                widget.user.userPhone,
              ),

              infoRow(
                Icons.email,
                "Email",
                widget.user.userEmail,
              ),

              infoRow(
                Icons.access_time,
                "Gender",
                "${widget.user.gender}",
              ),

              infoRow(
                Icons.badge,
                "Role",
                widget.user.role,
              ),

              infoRow(
                Icons.location_on,
                "Address",
                widget.user.fullAddress,
              ),

              infoRow(
                Icons.store,
                "Branch",
                widget.user.branchName,
              ),


              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(
      IconData icon,
      String title,
      String? value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),

          const SizedBox(width: 10),

          Text(
            "$title : ",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),

          Expanded(
            child: Text(
              value ?? "-",
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}