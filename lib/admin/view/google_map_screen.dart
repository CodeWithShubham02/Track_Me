import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/live_user_model.dart';

class GoogleMapScreen extends StatefulWidget {
  final String cid;
  const GoogleMapScreen({super.key, required this.cid});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {

  List<LiveUser> liveUsers = [];
  Set<Marker> markers = {};
  GoogleMapController? mapController;

  bool isLoading = true;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    fetchLiveUsers();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchLiveUsers();
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
  Future<void> fetchLiveUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/user_live_location.php?cid=${widget.cid}",
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == true) {
          List list = jsonData['data'];

          liveUsers = list
              .map((e) => LiveUser.fromJson(e))
              .where((u) =>
          u.latitude != null &&
              u.longitude != null)
              .toList();

          _addMarkers();
          if (mapController != null && markers.isNotEmpty) {
            _autoZoom();
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _addMarkers() {
    markers.clear();

    for (var user in liveUsers) {
      markers.add(
        Marker(
          markerId: MarkerId(user.uid),
          position: LatLng(user.latitude!, user.longitude!),
          infoWindow: InfoWindow(
            title: user.name,
            snippet: user.created_at,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    setState(() {});
  }

  void _autoZoom() {
    if (liveUsers.isEmpty || mapController == null) return;

    double minLat = liveUsers.first.latitude!;
    double maxLat = liveUsers.first.latitude!;
    double minLng = liveUsers.first.longitude!;
    double maxLng = liveUsers.first.longitude!;

    for (var user in liveUsers) {
      minLat = min(minLat, user.latitude!);
      maxLat = max(maxLat, user.latitude!);
      minLng = min(minLng, user.longitude!);
      maxLng = max(maxLng, user.longitude!);
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
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
        title: const Text(
          "Live Location",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
              _autoZoom();
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: 4,
            ),
            markers: markers,
          ),

          // 🔹 Bottom Active Count Card
          Positioned(
            bottom: 20,
            left: 60,
            right: 60,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black26,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    "Total Active Users: ${liveUsers.length}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}