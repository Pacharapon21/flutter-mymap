import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import '../widgets/app_drawer.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  List<LocationModel> _checkins = [];
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
    } catch (e) {
      print("Location error: $e");
    }

    try {
      _checkins = await _apiService.getCheckIns();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load friend locations',
          backgroundColor: Colors.red, colorText: Colors.white);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showMarkerInfo(LocationModel checkin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checkin.user?.name ?? 'Unknown User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${checkin.locationName ?? "Shared Location"}'),
            SizedBox(height: 8),
            Text('Lat: ${checkin.lat}'),
            Text('Lng: ${checkin.lng}'),
            if (checkin.description != null) ...[
              SizedBox(height: 8),
              Text('Note: ${checkin.description}'),
            ],
            SizedBox(height: 8),
            Text('Time: ${DateTime.parse(checkin.createdAt).toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(13.7563, 100.5018); // Default to Bangkok

    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.jirasak.whereamiapp',
                ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        width: 50,
                        height: 50,
                        child: Icon(Icons.my_location, color: Colors.blue, size: 40),
                      ),
                    ..._checkins.map((checkin) => Marker(
                          point: LatLng(checkin.lat, checkin.lng),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showMarkerInfo(checkin),
                            child: Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        )).toList(),
                  ],
                ),
              ],
            ),
    );
  }
}
