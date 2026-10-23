
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  bool loading = true;
  bool isSubmitting = false;

  List<dynamic> fields = [];

  Map<String, dynamic> formData = {};
  Map<String, File?> imageFiles = {};
  Map<String, bool> imageUploading = {};

  @override
  void initState() {
    super.initState();
    getFields();
  }

  // --------------------------------------------------
  // FETCH DYNAMIC FIELDS
  // --------------------------------------------------

  Future<void> getFields() async {
    try {
      final uri = Uri.https(
        'trackme.joizone.com',
        '/attendance/get_fields.php',
        {'template_id': widget.templateId},
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to load fields');
      }

      final decoded = jsonDecode(response.body);

      if (decoded['status'] == true) {
        final data = decoded['data'];

        if (data is List) {
          fields = List<dynamic>.from(data);
        }
      } else {
        debugPrint(
          'Get fields error: ${decoded['message']}',
        );
      }
    } catch (e) {
      debugPrint('Get fields exception: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // REQUIRED FIELD CHECK
  // Supports is_required: 1 or required: true
  // --------------------------------------------------

  bool isFieldRequired(dynamic field) {
    final value = field['is_required'] ?? field['required'];

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  // --------------------------------------------------
  // PICK AND UPLOAD IMAGE
  // --------------------------------------------------


  Future<void> pickImage(String fieldName) async {
    if (isSubmitting || imageUploading[fieldName] == true) {
      return;
    }

    // Show Camera / Gallery options
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.blue,
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Colors.green,
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );

    // User closed the dialog without selecting an option
    if (source == null) return;

    try {
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedImage == null) return;

      final File file = File(pickedImage.path);

      if (!mounted) return;

      setState(() {
        imageFiles[fieldName] = file;
        imageUploading[fieldName] = true;

        // Remove previous URL until new upload succeeds
        formData.remove(fieldName);
      });

      try {
        final Uint8List bytes = await file.readAsBytes();

        final String objectKey =
            'dynamic_forms/${widget.templateId}/'
            '${fieldName}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final String imageUrl = await uploadImageToS3(
          imageBytes: bytes,
          bucket: 'joizone-s3',
          objectKey: objectKey,
        );

        if (!mounted) return;

        setState(() {
          formData[fieldName] = imageUrl;
          imageUploading[fieldName] = false;
        });

        debugPrint('Uploaded image URL: $imageUrl');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
          ),
        );
      } catch (e) {
        debugPrint('Image upload error: $e');

        if (!mounted) return;

        setState(() {
          imageUploading[fieldName] = false;
          formData.remove(fieldName);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed. Please try again.'),
          ),
        );
      }

      // Refresh validation after upload
      if (mounted) {
        _formKey.currentState?.validate();
      }
    } catch (e) {
      debugPrint('Image picker error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Unable to open camera.'
                  : 'Unable to open gallery.',
            ),
          ),
        );
      }
    }
  }


  // --------------------------------------------------
  // AWS S3 UPLOAD
  // --------------------------------------------------

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
          'TohPtOvObC8NnBOp/1BM30tSr97U803JZ+gqI3Jf4uM=',
          'QWRTEfnfdys635',
        ),
        secretKey: decryptFMS(
          'Exz2WIEt2w1JRVZREvtIPeRX5Jti2p2mcHqs7Hh87/47BQidFAUAkLOxlzYFlctw',
          'QWRTEfnfdys635',
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

    return 'https://$bucket.s3.$region.amazonaws.com/$objectKey';
  }

  // --------------------------------------------------
  // SUBMIT FORM
  // --------------------------------------------------

  Future<void> submitForm() async {
    if (isSubmitting) return;

    // Prevent submitting while any image is uploading.
    final bool uploading = imageUploading.values.any(
          (value) => value,
    );

    if (uploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for image upload to finish.'),
        ),
      );
      return;
    }

    // Validate all fields.
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields correctly.',
          ),
        ),
      );
      return;
    }

    // Ensure required images have a successful upload URL.
    for (final field in fields) {
      if (field['field_type']?.toString() != 'image') {
        continue;
      }

      final String name = field['field_name']?.toString() ?? '';

      if (isFieldRequired(field) &&
          (formData[name] == null ||
              formData[name].toString().trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload ${field['field_label'] ?? name}.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final List<Map<String, dynamic>> values = [];

      for (final field in fields) {
        final String fieldName =
            field['field_name']?.toString() ?? '';

        values.add({
          'field_id': field['id'],
          'value': formData[fieldName] ?? '',
        });
      }

      final response = await http
          .post(
        Uri.parse(
          'https://trackme.joizone.com/attendance/'
              'submit_dynamic_form.php',
        ),
        body: {
          'template_id': widget.templateId,
          'uid': widget.uid,
          'cid': widget.cid,
          'branch_name': widget.branchName,
          'form_data': jsonEncode(values),
        },
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (decoded['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form Submitted Successfully'),
          ),
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (mounted) {
          Get.back(result: true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded['message']?.toString() ??
                  'Submission Failed',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit form error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Submission failed. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // FIELD BUILDER
  // --------------------------------------------------

  Widget buildField(dynamic field) {
    final String fieldName =
        field['field_name']?.toString() ?? '';

    final String fieldLabel =
        field['field_label']?.toString() ?? 'Field';

    final String fieldType =
        field['field_type']?.toString() ?? 'text';

    final bool required = isFieldRequired(field);

    final String? Function(String?) textValidator = (value) {
      if (required &&
          (value == null || value.trim().isEmpty)) {
        return '$fieldLabel is required';
      }

      if (fieldType == 'number' &&
          value != null &&
          value.trim().isNotEmpty &&
          num.tryParse(value.trim()) == null) {
        return 'Please enter a valid number';
      }

      return null;
    };

    switch (fieldType) {
    // ----------------------------------------------
    // TEXT FIELD
    // ----------------------------------------------

      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: TextFormField(
            enabled: !isSubmitting,
            decoration: InputDecoration(
              labelText: required
                  ? '$fieldLabel *'
                  : fieldLabel,
              border: const OutlineInputBorder(),
            ),
            validator: textValidator,
            onChanged: (value) {
              formData[fieldName] = value;
            },
          ),
        );

    // ----------------------------------------------
    // NUMBER FIELD
    // ----------------------------------------------

      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: TextFormField(
            enabled: !isSubmitting,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            decoration: InputDecoration(
              labelText: required
                  ? '$fieldLabel *'
                  : fieldLabel,
              border: const OutlineInputBorder(),
            ),
            validator: textValidator,
            onChanged: (value) {
              formData[fieldName] = value;
            },
          ),
        );

    // ----------------------------------------------
    // DROPDOWN FIELD
    // ----------------------------------------------

      case 'dropdown':
        final List<dynamic> options =
        field['options'] is List
            ? field['options']
            : [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: required
                  ? '$fieldLabel *'
                  : fieldLabel,
              border: const OutlineInputBorder(),
            ),
            items: options.map<DropdownMenuItem<String>>(
                  (option) {
                final String value = option.toString();

                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              },
            ).toList(),
            validator: (value) {
              if (required &&
                  (value == null || value.isEmpty)) {
                return 'Please select $fieldLabel';
              }

              return null;
            },
            onChanged: isSubmitting
                ? null
                : (value) {
              if (value != null) {
                formData[fieldName] = value;
              } else {
                formData.remove(fieldName);
              }
            },
          ),
        );

    // ----------------------------------------------
    // IMAGE FIELD
    // ----------------------------------------------

      case 'image':
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FormField<File>(
            validator: (value) {
              if (required &&
                  (imageFiles[fieldName] == null ||
                      formData[fieldName] == null ||
                      formData[fieldName]
                          .toString()
                          .trim()
                          .isEmpty)) {
                return 'Please capture and upload $fieldLabel';
              }

              return null;
            },
            builder: (formFieldState) {
              final bool uploading =
                  imageUploading[fieldName] == true;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required
                        ? '$fieldLabel *'
                        : fieldLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: isSubmitting || uploading
                            ? null
                            : () async {
                          await pickImage(fieldName);

                          if (!mounted) return;

                          formFieldState.didChange(
                            imageFiles[fieldName],
                          );

                          formFieldState.validate();
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius:
                            BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 35,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      if (imageFiles[fieldName] != null)
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(10),
                          child: Image.file(
                            imageFiles[fieldName]!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (uploading) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (formFieldState.hasError)
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 8),
                      child: Text(
                        formFieldState.errorText!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );

    // ----------------------------------------------
    // DEFAULT FIELD
    // ----------------------------------------------

      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: TextFormField(
            enabled: !isSubmitting,
            decoration: InputDecoration(
              labelText: required
                  ? '$fieldLabel *'
                  : fieldLabel,
              border: const OutlineInputBorder(),
            ),
            validator: textValidator,
            onChanged: (value) {
              formData[fieldName] = value;
            },
          ),
        );
    }
  }

  // --------------------------------------------------
  // BUILD UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          widget.formName,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : fields.isEmpty
          ? const Center(
        child: Text('No fields found for this form.'),
      )
          : Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: fields.length + 1,
          itemBuilder: (context, index) {
            if (index == fields.length) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xff2563EB),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child:
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            return buildField(fields[index]);
          },
        ),
      ),
    );
  }
}
