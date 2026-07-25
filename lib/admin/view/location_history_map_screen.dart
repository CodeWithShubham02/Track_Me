import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/fetch_location_history_model.dart';

class LocationHistoryMapScreen extends StatefulWidget {
  final String attendance_id;
  final String branch_lat;
  final String branch_long;

  const LocationHistoryMapScreen({
    super.key,
    required this.attendance_id,
    required this.branch_lat,
    required this.branch_long,
  });

  @override
  State<LocationHistoryMapScreen> createState() =>
      _LocationHistoryMapScreenState();
}

class _LocationHistoryMapScreenState
    extends State<LocationHistoryMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  List<LocationHistoryModel> locationList = [];
  bool isLoading = true;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    locationList =
    await fetchLocationHistory(widget.attendance_id);

    _prepareMapData();

    setState(() {
      isLoading = false;
    });
  }

  Future<List<LocationHistoryModel>> fetchLocationHistory(
      String attendanceId) async {
    final response = await http.get(
      Uri.parse(
          "http://15.206.209.30/attendance/fetch_location_history.php?attendance_id=$attendanceId"),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) =>
          LocationHistoryModel.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
  int? selectedIndex;
  Future<void> moveToLocation(double lat, double lng, String time) async {
    final controller = await _controller.future;

    const markerId = MarkerId("selected_location");

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "selected_location");

      _markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: "User Current Here",
            snippet: formatDateTime(time),
          ),
        ),
      );
    });

    // zoom to location
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        18,
      ),
    );

    // open info window automatically
    controller.showMarkerInfoWindow(markerId);
  }
  String formatTime12(String dateTime) {
    DateTime dt = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(dt);
  }
  void _prepareMapData() {
    _markers.clear();
    _polylines.clear();
    _routePoints.clear();

    // 🏢 Branch Marker
    final branchLat = double.tryParse(widget.branch_lat) ?? 0.0;
    final branchLng = double.tryParse(widget.branch_long) ?? 0.0;

    if (branchLat != 0.0 && branchLng != 0.0) {
      final branchPosition = LatLng(branchLat, branchLng);

      _markers.add(
        Marker(
          markerId: const MarkerId('branch'),
          position: branchPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Kiosk Location"),
        ),
      );

      _initialPosition = branchPosition;
    }

    // 🚶 User Route
    for (int i = 0; i < locationList.length; i++) {
      final item = locationList[i];

      // ✅ DIRECT USE (NO tryParse, NO cast)
      final lat = item.latitude;
      final lng = item.longitude;

      if (lat == 0.0 || lng == 0.0) continue;

      final point = LatLng(lat, lng);
      _routePoints.add(point);

      BitmapDescriptor color;

      if (i == selectedIndex) {
        color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange); // highlighted marker
      } else if (i == 0) {
        color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue);
      } else if (i == locationList.length - 1) {
        color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      } else {
        color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen);
      }

      _markers.add(
        Marker(
          markerId: MarkerId("user_$i"),
          position: point,
          icon: color,
          infoWindow: InfoWindow(
            title: "User Movement",
            snippet: formatTime12(item.createdAt),
          ),
        ),
      );
    }

    // 🛣 Polyline
    if (_routePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("movement_route"),
          points: _routePoints,
          width: 5,
          color: Colors.blue,
        ),
      );
    }

    // 📍 Fallback
    if (_initialPosition == null && _routePoints.isNotEmpty) {
      _initialPosition = _routePoints.first;
    }

    _initialPosition ??= const LatLng(20.5937, 78.9629);
  }

  Future<void> _fitCamera() async {
    if (_routePoints.isEmpty) return;

    final controller = await _controller.future;

    if (_routePoints.length == 1) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
            _routePoints.first, 16),
      );
      return;
    }

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      minLat =
      minLat < p.latitude ? minLat : p.latitude;
      maxLat =
      maxLat > p.latitude ? maxLat : p.latitude;
      minLng =
      minLng < p.longitude ? minLng : p.longitude;
      maxLng =
      maxLng > p.longitude ? maxLng : p.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }
  Future<void> openMap(
      double userLat, double userLng, double branchLat, double branchLng) async {

    final Uri url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$branchLat,$branchLng&travelmode=Driving");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {

    double distanceInMeters = Geolocator.distanceBetween(
        startLat, startLng, endLat, endLng);

    return distanceInMeters;
  }
  String formatDateTime(String dateTime) {
    DateTime dt = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(dt);
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator()),
      );
    }

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
        iconTheme:
        const IconThemeData(color: Colors.white),
        title: Text(
          "Live Location History (${locationList.length})",
          style: const TextStyle(
              color: Colors.white,fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 🗺 MAP
            SizedBox(
              height: 400,
              child: GoogleMap(
                initialCameraPosition:
                CameraPosition(
                  target: _initialPosition!,
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                onMapCreated: (controller) {
                  _controller.complete(controller);
                  _fitCamera();
                },
              ),
            ),

            // 📋 LIST
            Expanded(
              child: locationList.isEmpty
                  ? const Center(
                child:
                Text("No location data"),
              )
                  : ListView.builder(
                itemCount:
                locationList.length,
                itemBuilder:
                    (context, index) {
                  final item =
                  locationList[index];

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4),
                    child: ListTile(
                      onTap: () async {

                        setState(() {
                          selectedIndex = index;
                        });

                        _prepareMapData();

                        moveToLocation(
                          item.latitude,
                          item.longitude,
                          item.createdAt,
                        );
                      },
                      leading: InkWell(
                        onTap: (){
                          //I have a branch lat,long
                          //user lat long
                          //open the google map with route branch,user
                          double userLat = double.tryParse(item.latitude.toString()) ?? 0.0;
                          double userLng = double.tryParse(item.longitude.toString()) ?? 0.0;
                          // 🏢 Branch Marker
                          final branchLat = double.tryParse(widget.branch_lat) ?? 0.0;
                          final branchLng = double.tryParse(widget.branch_long) ?? 0.0;
                          openMap(
                            userLat,
                            userLng,
                            branchLat,
                            branchLng,
                          );
                        },
                        child: const Icon(
                            Icons.location_on,
                            color: Colors.green),
                      ),
                      title: Row(
                        children: [
                          Text(
                              "Lat: ${item.latitude},\nLng: ${item.longitude}",overflow:TextOverflow.ellipsis,style: TextStyle(fontSize: 16),),
                          IconButton(onPressed: (){
                            double userLat = double.tryParse(item.latitude.toString()) ?? 0.0;
                            double userLng = double.tryParse(item.longitude.toString()) ?? 0.0;
                            // 🏢 Branch Marker
                            final branchLat = double.tryParse(widget.branch_lat) ?? 0.0;
                            final branchLng = double.tryParse(widget.branch_long) ?? 0.0;
                            double distance = calculateDistance(
                                userLat, userLng, branchLat, branchLng);

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Distance"),
                                content: Text("Distance from branch: ${distance.toStringAsFixed(2)} meters"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  )
                                ],
                              ),
                            );
                          }, icon: Icon(Icons.directions))
                        ],
                      ),
                      subtitle:
                          Text("Time: ${formatDateTime(item.createdAt)}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}