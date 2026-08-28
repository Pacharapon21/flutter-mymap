import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../services/location_service.dart';

class MapDetailPage extends StatefulWidget {
  final LocationModel checkIn;

  const MapDetailPage({super.key, required this.checkIn});

  @override
  State<MapDetailPage> createState() => _MapDetailPageState();
}

class _MapDetailPageState extends State<MapDetailPage> {
  final LocationService _locationService = LocationService();
  late final MapController _mapController;

  LatLng? _myLocation;
  List<LatLng> _routePoints = [];
  double? _distanceKm;
  double? _durationMinutes;
  bool _isLoadingRoute = true;
  bool _isLocating = false;
  String _travelMode = 'driving'; // 'driving' or 'walking'

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initCurrentLocationAndRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocationAndRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        final myLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _myLocation = myLatLng;
        });

        // Calculate distance and get route
        await _fetchRoute(myLatLng, LatLng(widget.checkIn.lat, widget.checkIn.lng));
      } else {
        _fallbackDistanceOnly();
      }
    } catch (_) {
      _fallbackDistanceOnly();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _fallbackDistanceOnly() {
    if (_myLocation != null) {
      final double meters = Geolocator.distanceBetween(
        _myLocation!.latitude,
        _myLocation!.longitude,
        widget.checkIn.lat,
        widget.checkIn.lng,
      );
      setState(() {
        _distanceKm = meters / 1000.0;
        _durationMinutes = (_distanceKm! / 40.0) * 60; // Approx 40 km/h
        _routePoints = [
          _myLocation!,
          LatLng(widget.checkIn.lat, widget.checkIn.lng),
        ];
      });
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final mode = _travelMode == 'driving' ? 'driving' : 'walking';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$mode/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distanceMeters = (route['distance'] as num).toDouble();
          final double durationSeconds = (route['duration'] as num).toDouble();

          final List coordinates = route['geometry']['coordinates'];
          final List<LatLng> points = coordinates.map<LatLng>((coord) {
            return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
          }).toList();

          if (mounted) {
            setState(() {
              _distanceKm = distanceMeters / 1000.0;
              _durationMinutes = durationSeconds / 60.0;
              _routePoints = points;
            });

            _fitRouteBounds();
          }
          return;
        }
      }
    } catch (_) {
      // If OSRM fails or timeout, fallback to straight line
    }

    _fallbackDistanceOnly();
    _fitRouteBounds();
  }

  void _fitRouteBounds() {
    if (_myLocation == null) {
      _recenterFriend();
      return;
    }

    final friendLocation = LatLng(widget.checkIn.lat, widget.checkIn.lng);
    final bounds = LatLngBounds.fromPoints([_myLocation!, friendLocation]);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(48, 80, 48, 220),
        ),
      );
    } catch (_) {
      final centerLat = (_myLocation!.latitude + friendLocation.latitude) / 2;
      final centerLng = (_myLocation!.longitude + friendLocation.longitude) / 2;
      _mapController.move(LatLng(centerLat, centerLng), 13.0);
    }
  }

  void _recenterFriend() {
    final latLng = LatLng(widget.checkIn.lat, widget.checkIn.lng);
    _mapController.move(latLng, 15.0);
  }

  void _recenterMe() async {
    if (_myLocation != null) {
      _mapController.move(_myLocation!, 15.5);
      return;
    }

    setState(() => _isLocating = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null && mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() => _myLocation = loc);
        _mapController.move(loc, 15.5);
        _fetchRoute(loc, LatLng(widget.checkIn.lat, widget.checkIn.lng));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  String _formatDate(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return createdAt;
    }
  }

  String _formatDistance(double? km) {
    if (km == null) return 'กำลังคำนวณ...';
    if (km < 1.0) {
      return '${(km * 1000).toInt()} ม.';
    }
    return '${km.toStringAsFixed(1)} กม.';
  }

  String _formatDuration(double? minutes) {
    if (minutes == null) return 'กำลังคำนวณ...';
    if (minutes < 60) {
      return '~${minutes.ceil()} นาที';
    }
    final int hours = minutes ~/ 60;
    final int remainingMins = (minutes % 60).toInt();
    return '~$hours ชม. ${remainingMins > 0 ? '$remainingMins นาที' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = widget.checkIn;
    final friendLatLng = LatLng(checkIn.lat, checkIn.lng);
    final userName = checkIn.user?.name ?? 'เพื่อน';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final locationName = checkIn.locationName ?? 'พิกัดที่แชร์';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ==============================
          // 1. FULLSCREEN INTERACTIVE MAP
          // ==============================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: friendLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.jirasak.whereamiapp',
              ),

              // Route Polyline Layer
              if (_routePoints.isNotEmpty) ...[
                // Outer Glow / Border for the polyline
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF312E81).withValues(alpha: 0.3),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ],

              // Markers Layer
              MarkerLayer(
                markers: [
                  // --- User's Current Location Marker ---
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 90,
                      height: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Text(
                              'คุณอยู่ที่นี่',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF10B981),
                              child: Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- Friend's Location Marker ---
                  Marker(
                    point: friendLatLng,
                    width: 100,
                    height: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF4F46E5),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ==============================
          // 2. TOP APP BAR OVERLAY
          // ==============================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_rounded, color: Color(0xFF4F46E5), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เส้นทางไปหา $userName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==============================
          // 3. FLOATING MAP CONTROLS
          // ==============================
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.zoom_out_map_rounded,
                  tooltip: 'จัดมุมมองพอดีเส้นทาง',
                  onTap: _fitRouteBounds,
                  color: Colors.white,
                  iconColor: const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.person_pin_circle_rounded,
                  tooltip: 'ไปที่ตำแหน่งเพื่อน',
                  onTap: _recenterFriend,
                  color: Colors.white,
                  iconColor: const Color(0xFFEA580C),
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'ตำแหน่งของฉัน',
                  onTap: _recenterMe,
                  color: const Color(0xFF4F46E5),
                  iconColor: Colors.white,
                  isLoading: _isLocating,
                ),
              ],
            ),
          ),

          // ==============================
          // 4. BOTTOM ROUTE & DISTANCE PANEL
          // ==============================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Route Metrics Header (Distance & Time Pills)
                  Row(
                    children: [
                      // Distance Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.straighten_rounded, color: Color(0xFF4F46E5), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ระยะทาง',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _formatDistance(_distanceKm),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF312E81),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Time Estimate Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _travelMode == 'driving' ? Icons.directions_car_rounded : Icons.directions_walk_rounded,
                                color: const Color(0xFF16A34A),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'เวลาเดินทาง',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _formatDuration(_durationMinutes),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mode Toggle (Car / Walk)
                  Row(
                    children: [
                      _buildModeChip('🚗 ขับรถ', 'driving'),
                      const SizedBox(width: 8),
                      _buildModeChip('🚶 เดินเท้า', 'walking'),
                      const Spacer(),
                      if (_isLoadingRoute)
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'กำลังค้นหาเส้นทาง...',
                              style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5)),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Origin & Destination Info
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF10B981)),
                          Container(width: 2, height: 24, color: Colors.grey.shade300),
                          const Icon(Icons.location_on, size: 18, color: Color(0xFF4F46E5)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ตำแหน่งของคุณ (จุดเริ่มต้น)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$userName · $locationName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'เช็คอินเมื่อ ${_formatDate(checkIn.createdAt)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            if (checkIn.description != null && checkIn.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  '"${checkIn.description}"',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                        tooltip: 'คำนวณเส้นทางใหม่',
                        onPressed: _initCurrentLocationAndRoute,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, String mode) {
    final bool isSelected = _travelMode == mode;
    return GestureDetector(
      onTap: () {
        if (_travelMode != mode) {
          setState(() => _travelMode = mode);
          if (_myLocation != null) {
            _fetchRoute(_myLocation!, LatLng(widget.checkIn.lat, widget.checkIn.lng));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: iconColor, strokeWidth: 2),
                )
              : Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
