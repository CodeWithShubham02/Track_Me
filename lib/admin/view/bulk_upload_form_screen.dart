import 'package:flutter/material.dart';

class BulkUploadFormScreen extends StatefulWidget {
  final String cid;
  const BulkUploadFormScreen({super.key,required this.cid});

  @override
  State<BulkUploadFormScreen> createState() => _BulkUploadFormScreenState();
}

class _BulkUploadFormScreenState extends State<BulkUploadFormScreen> {
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
          "Bulk Upload Client Form ",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
