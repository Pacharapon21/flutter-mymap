import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

// จุดเริ่มต้น: กรุงเทพฯ ประเทศไทย
const _defaultThailand = LatLng(13.7563, 100.5018);

// ตัวเลือกกิจกรรมยอดนิยม
const _activityOptions = [
  '🍽️ กินข้าว',
  '☕ นั่งคาเฟ่',
  '🏢 ประชุมงาน',
  '🛒 ช้อปปิ้ง',
  '🏋️ ออกกำลังกาย',
  '🎮 เล่นเกม',
  '📚 เรียนหนังสือ',
  '🚗 เดินทาง',
  '🏖️ พักผ่อน',
  '🤝 พบเพื่อน',
];

class CheckInDialog extends StatefulWidget {
  const CheckInDialog({super.key});

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final TextEditingController _noteController = TextEditingController();

  // เริ่มต้นที่กรุงเทพฯ เสมอ — ไม่ auto-jump ไป GPS
  LatLng _selectedLatLng = _defaultThailand;
  double _accuracy = 0.0;
  bool _isLocatingGps = false;
  bool _isSubmitting = false;
  String? _selectedActivity;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // กดปุ่ม GPS ค่อยย้าย — ไม่ทำอัตโนมัติ
  Future<void> _jumpToGps() async {
    setState(() => _isLocatingGps = true);
    try {
      Position? position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLatLng = userLatLng;
          _accuracy = position.accuracy;
          _isLocatingGps = false;
        });
        _mapController.move(userLatLng, 16.0);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
        Get.snackbar('ไม่สามารถหาตำแหน่งได้', 'กรุณาเปิด GPS แล้วลองใหม่',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    }
  }

  String get _description {
    final parts = <String>[];
    if (_selectedActivity != null) parts.add(_selectedActivity!);
    if (_noteController.text.trim().isNotEmpty) parts.add(_noteController.text.trim());
    return parts.isEmpty ? 'Live shared location from app' : parts.join(' — ');
  }

  void _confirmLocation() async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.createCheckIn(
        _selectedLatLng.latitude,
        _selectedLatLng.longitude,
        _accuracy,
        description: _description,
      );
      Navigator.of(context).pop();
      Get.snackbar(
        'เช็คอินสำเร็จ! ✅',
        _selectedActivity != null ? 'สนุกกับ $_selectedActivity นะครับ' : 'บันทึกตำแหน่งแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', 'ไม่สามารถเช็คอินได้ กรุณาลองใหม่',
          backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_location_alt, color: Colors.indigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เช็คอิน',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          'แตะบนแผนที่เพื่อเลือกตำแหน่ง',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Map ───
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultThailand, // เริ่มที่ไทยเสมอ
                      initialZoom: 11.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLatLng = point;
                          _accuracy = 0.0;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.appflutter.locationapp',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLatLng,
                            width: 50,
                            height: 50,
                            alignment: Alignment.topCenter,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ปุ่ม GPS มุมขวาล่าง
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton.small(
                      heroTag: 'gps_btn',
                      backgroundColor: Colors.white,
                      elevation: 3,
                      onPressed: _isLocatingGps ? null : _jumpToGps,
                      child: _isLocatingGps
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.indigo, strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Coordinates ───
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${_selectedLatLng.latitude.toStringAsFixed(5)},  Lng: ${_selectedLatLng.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.indigo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ─── กำลังทำอะไร? ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กำลังทำอะไรอยู่?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // Activity chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _activityOptions.map((activity) {
                      final isSelected = _selectedActivity == activity;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedActivity = isSelected ? null : activity;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.indigo : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Free text note
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'เพิ่มโน้ตเพิ่มเติม... (ไม่บังคับ)',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.indigo),
                      ),
                      counterStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // ─── Buttons ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('เช็คอินเลย!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
