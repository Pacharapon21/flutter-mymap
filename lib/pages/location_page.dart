import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position? position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      Get.snackbar('Location Error', e.toString(),
          backgroundColor: Colors.orange, colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareLocation() async {
    if (_currentPosition == null) {
      Get.snackbar('Error', 'No location to share',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.createCheckIn(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentPosition!.accuracy,
      );
      Get.snackbar('Success', 'Location shared successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to share location',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location')),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 80, color: Colors.green),
                    SizedBox(height: 20),
                    if (_currentPosition != null) ...[
                      Text('Latitude: ${_currentPosition!.latitude}',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Longitude: ${_currentPosition!.longitude}',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Accuracy: ${_currentPosition!.accuracy} meters',
                          style: TextStyle(fontSize: 18)),
                    ] else
                      Text('Location not available',
                          style: TextStyle(fontSize: 18)),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _refreshLocation,
                          icon: Icon(Icons.refresh),
                          label: Text('Refresh'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _shareLocation,
                          icon: Icon(Icons.share),
                          label: Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
