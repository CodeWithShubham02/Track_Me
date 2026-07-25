import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/attendance_location_model.dart';

class AttendanceRouteMapScreen extends StatefulWidget {
  final List<AttendanceLocationModel> data;

  const AttendanceRouteMapScreen({
    super.key,
    required this.data,
  });

  @override
  State<AttendanceRouteMapScreen> createState() =>
      _AttendanceRouteMapScreenState();
}

class _AttendanceRouteMapScreenState
    extends State<AttendanceRouteMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  LatLng? _initialPosition; // ✅ nullable (NO late)

  @override
  void initState() {
    super.initState();
    _prepareMapData();
  }

  void _prepareMapData() {
    if (widget.data.isEmpty) {
      _initialPosition = const LatLng(20.5937, 78.9629); // India fallback
      return;
    }

    _loadOfficeMarker();
    _loadRoute();

    // Agar office se set nahi hua
    if (_initialPosition == null && _routePoints.isNotEmpty) {
      _initialPosition = _routePoints.first;
    }

    // Final fallback
    _initialPosition ??= const LatLng(20.5937, 78.9629);

    setState(() {});
  }
  Future<void> openGoogleMap(double lat, double lng) async {
    final url = "https://www.google.com/maps?q=$lat,$lng";
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.platformDefault, // 👈 IMPORTANT
    )) {
      throw 'Could not launch Google Maps';
    }
  }
  void _loadOfficeMarker() {
    final officeLat = _toDouble(widget.data.first.blatitude);
    final officeLng = _toDouble(widget.data.first.blongitude);

    if (officeLat == 0 || officeLng == 0) return;

    final officeLatLng = LatLng(officeLat, officeLng);

    _markers.add(
      Marker(
        markerId: const MarkerId('office'),
        position: officeLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: "Office Location"),
      ),
    );

    _initialPosition = officeLatLng;
  }

  void _loadRoute() {
    for (int i = 0; i < widget.data.length; i++) {
      final item = widget.data[i];

      final lat = double.tryParse(item.latitude);
      final lng = double.tryParse(item.longitude);

      if (lat == null || lng == null) continue;

      final point = LatLng(lat, lng);
      _routePoints.add(point);

      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: item.name ?? 'User',
            snippet: item.createdAt,
          ),
        ),
      );
    }

    if (_routePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('user_route'),
          points: _routePoints,
          width: 5,
          color: Colors.blue,
        ),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// 🔥 Auto fit camera to route
  Future<void> _fitCameraToRoute() async {
    if (_routePoints.isEmpty) return;

    final controller = await _controller.future;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    controller.animateCamera(
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
    if (_initialPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
        title: const Text("Real Time Location Tracking",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition!,
                zoom: 16,
              ),
              mapType: MapType.normal,
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: true,
              onMapCreated: (controller) {
                _controller.complete(controller);
                _fitCameraToRoute();
              },
            ),
          ),
          Expanded(
            child: widget.data.isEmpty
                ? const Center(child: Text("No location data"))
                : ListView.builder(
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final item = widget.data[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: InkWell(
                      onTap: (){
                        double lat = double.parse(item.latitude);
                        double lng = double.parse(item.longitude);

                        openGoogleMap(lat, lng);
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(item.name ?? 'User'),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text("Lat: ${item.latitude}"),
                        Text("Lng: ${item.longitude}"),
                        Text("Time: ${item.createdAt}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
