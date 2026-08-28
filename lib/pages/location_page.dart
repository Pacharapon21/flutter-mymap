import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/check_in_dialog.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isSharing = false;

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
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      Get.snackbar(
        'การค้นหาพิกัดผิดพลาด',
        e.toString(),
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareLocationQuick() async {
    if (_currentPosition == null) {
      Get.snackbar(
        'ไม่พบพิกัด',
        'กรุณารอโหลดพิกัด GPS ก่อนทำการแชร์',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSharing = true);

    try {
      await _apiService.createCheckIn(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentPosition!.accuracy,
        locationName: 'แชร์ตำแหน่งปัจจุบัน',
        description: 'แชร์ตำแหน่งเรียลไทม์จากหน้าพิกัด GPS',
      );
      Get.snackbar(
        'แชร์พิกัดสำเร็จ!',
        'ตำแหน่งของคุณถูกบันทึกและแชร์ให้กับเพื่อนๆ เรียบร้อยแล้ว',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'แชร์พิกัดไม่สำเร็จ',
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('พิกัดตำแหน่งของฉัน', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'อัปเดตพิกัด GPS',
            onPressed: _isLoading ? null : _refreshLocation,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // GPS Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Icon(Icons.satellite_alt_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading
                        ? 'กำลังค้นหาสัญญาณดาวเทียม GPS...'
                        : _currentPosition != null
                            ? 'เชื่อมต่อสัญญาณ GPS สำเร็จ'
                            : 'ไม่พบสัญญาณ GPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentPosition != null
                        ? 'ความแม่นยำประมาณ ±${_currentPosition!.accuracy.toStringAsFixed(1)} เมตร'
                        : 'กรุณาเปิดสิทธิ์การเข้าถึงตำแหน่งของอุปกรณ์',
                    style: TextStyle(
                      color: Colors.indigo.shade100,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Coordinates Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลพิกัดละติจูด-ลองจิจูด',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCoordinateRow(
                    icon: Icons.north_rounded,
                    label: 'ละติจูด (Latitude)',
                    value: _currentPosition != null
                        ? _currentPosition!.latitude.toStringAsFixed(6)
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildCoordinateRow(
                    icon: Icons.east_rounded,
                    label: 'ลองจิจูด (Longitude)',
                    value: _currentPosition != null
                        ? _currentPosition!.longitude.toStringAsFixed(6)
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildCoordinateRow(
                    icon: Icons.gps_fixed_rounded,
                    label: 'ระดับความแม่นยำ (Accuracy)',
                    value: _currentPosition != null
                        ? '${_currentPosition!.accuracy.toStringAsFixed(1)} เมตร'
                        : '-',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _refreshLocation,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('รีเฟรชพิกัด'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || _isSharing || _currentPosition == null)
                          ? null
                          : _shareLocationQuick,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.share_location_rounded),
                      label: const Text('แชร์ตำแหน่ง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CheckInDialog(),
                  );
                },
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('เช็คอินพร้อมปักหมุดบนแผนที่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
