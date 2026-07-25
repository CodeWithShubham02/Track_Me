import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleLocationScreen extends StatefulWidget {
  const GoogleLocationScreen({super.key});

  @override
  State<GoogleLocationScreen> createState() => _GoogleLocationScreenState();
}

class _GoogleLocationScreenState extends State<GoogleLocationScreen> {


  double defaultLat=19.0933819;
  double defaultLong=72.8471858;

  GoogleMapController? mapController;

  LatLng officeLatLng = const LatLng(18.5196, 73.8553); // Office
  LatLng? currentLatLng;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    currentLatLng = LatLng(position.latitude, position.longitude);

    markers.add(
      Marker(
        markerId: const MarkerId("current"),
        position: currentLatLng!,
        infoWindow: const InfoWindow(title: "You are here"),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId("office"),
        position: officeLatLng,
        infoWindow: const InfoWindow(title: "Office"),
      ),
    );

    setState(() {});
  }
  Future<void> getDirections() async {
    if (currentLatLng == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${currentLatLng!.latitude},${currentLatLng!.longitude}"
        "&destination=${officeLatLng.latitude},${officeLatLng.longitude}"
        "&mode=driving"
        "&key=AIzaSyBF7OlUqnsWTXRMiwtwEk9ieQ4YkzIhq18";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    print("-----------");
    print(response.body);
    print(data);
    if (data['routes'] == null || data['routes'].isEmpty) {
      debugPrint("❌ No routes found: ${data['status']}");
      return;
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    final List<LatLng> polylineCoords = decodePolyline(points);

    polylines.clear();
    polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 6,
        points: polylineCoords,
      ),
    );

    setState(() {});

    _fitCameraToRoute(polylineCoords);
  }
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

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
  @override
  void initState() {
    super.initState();
    getCurrentLocation().then((_) async {
      await Future.delayed(const Duration(seconds: 1));
      getDirections();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Maps"),
      ),
      body: SizedBox(
        height: 300,
        child: Stack(
          children: [GoogleMap(
        initialCameraPosition: CameraPosition(
        target: officeLatLng,
          zoom: 14.5,
        ),
        myLocationEnabled: true,
        markers: markers,
        polylines: polylines,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
            // Center(
            //   child: Icon(Icons.location_on,color: Colors.red,size: 50,),
            // )
        ]
        ),
      ),
      // bottomSheet: Container(
      //   color: Colors.green[100],
      //   padding: EdgeInsets.only(left: 25,right: 10),
      //   height: 80,
      //   child: Row(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Icon(Icons.location_on),
      //       Expanded(child: Text("vdfvgffffffffffffffffffffffffdefrerfredjjs",style: TextStyle(fontSize: 20),))
      //     ],
      //   ),
      // ),
    );
  }
}
