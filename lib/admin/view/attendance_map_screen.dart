import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:joizone/admin/model/attendance_location_model.dart';

class GoogleLocationMapScreen extends StatefulWidget {
  final AttendanceLocationModel data;

  const GoogleLocationMapScreen({super.key, required this.data});

  @override
  State<GoogleLocationMapScreen> createState() =>
      _GoogleLocationMapScreenState();
}

class _GoogleLocationMapScreenState extends State<GoogleLocationMapScreen> {
  GoogleMapController? mapController;

  LatLng? officeLatLng;
  LatLng? currentLatLng;
  String? name;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  int distanceInMeters = 0;

  @override
  void initState() {
    super.initState();

    officeLatLng = LatLng(
      _toDouble(widget.data.blatitude),
      _toDouble(widget.data.blongitude),
    );
    name=widget.data.name;

    currentLatLng = LatLng(
      _toDouble(widget.data.latitude),
      _toDouble(widget.data.longitude),
    );

    _addMarkers();
    loadLiveLocation();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ---------------- MARKERS ----------------
  void _addMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId("office"),
        position: officeLatLng!,
        infoWindow: const InfoWindow(title: "Office"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
      Marker(
        markerId: const MarkerId("user"),
        position: currentLatLng!,
        infoWindow: InfoWindow(title: "${name}"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    };
  }

  // ---------------- DIRECTIONS ----------------
  Future<void> getDirections() async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${currentLatLng!.latitude},${currentLatLng!.longitude}"
        "&destination=${officeLatLng!.latitude},${officeLatLng!.longitude}"
        "&mode=driving"
        "&key=YOUR_GOOGLE_MAPS_API_KEY";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['routes'] == null || data['routes'].isEmpty) {
      debugPrint("❌ No route found");
      return;
    }

    final route = data['routes'][0];
    final points = route['overview_polyline']['points'];

    // ✅ distance in meters
    distanceInMeters =
    route['legs'][0]['distance']['value'];

    final polylineCoords = decodePolyline(points);

    polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 6,
        points: polylineCoords,
      ),
    };

    setState(() {});
    _fitCameraToRoute(polylineCoords);
  }

  // ---------------- CAMERA FIT ----------------
  void _fitCameraToRoute(List<LatLng> points) {
    if (points.isEmpty || mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  // ---------------- POLYLINE DECODE ----------------
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  // ---------------- UI ----------------
  double? currentDistance;
  Future<void> loadLiveLocation() async {
    final officeLat = officeLatLng!.latitude;
    final officeLng = officeLatLng!.longitude;
    final dist = calculateDistance(
      officeLat,
      officeLng,
      currentLatLng!.latitude,
     currentLatLng!.longitude,
    );

    setState(() {
      currentDistance = dist;
    });
  }
  double calculateDistance(
      double officeLat,
      double officeLng,
      double userLat,
      double userLng,
      ) {
    return Geolocator.distanceBetween(
      officeLat,
      officeLng,
      userLat,
      userLng,
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
          title: const Text("Attendance Route Map",style: TextStyle(color: Colors.white),)),
      body: Column(
        children: [
          SizedBox(
            height: 500,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: officeLatLng!,
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              onMapCreated: (controller) {
                mapController = controller;
                getDirections(); // ✅ CALL AFTER MAP READY
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Distance : $currentDistance meters",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
