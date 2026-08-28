import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/check_in_dialog.dart';
import '../services/api_service.dart';
import '../models/location_model.dart';
import 'map_detail_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ApiService _apiService = ApiService();
  List<LocationModel> _checkIns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    setState(() => _isLoading = true);
    try {
      // ดึงข้อมูลเช็คอินจาก API จริง (ไม่ใช่ mock)
      final checkIns = await _apiService.getCheckIns();
      setState(() {
        _checkIns = checkIns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 12),
                  Text('กำลังโหลดฟีดเช็คอิน...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          : _checkIns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded, size: 54, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีการเช็คอินในระบบ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'กดปุ่ม "เช็คอินตอนนี้" ด้านล่างเพื่อแชร์พิกัดเป็นคนแรก!',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F46E5),
              onRefresh: _loadCheckIns,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 12.0, bottom: 88.0),
                itemCount: _checkIns.length,
                itemBuilder: (context, index) {
                  return _buildLocationCard(context, _checkIns[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const CheckInDialog(),
          );
          _loadCheckIns();
        },
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text(
          'เช็คอินตอนนี้',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, LocationModel checkIn) {
    final latLng = LatLng(checkIn.lat, checkIn.lng);
    final userName = checkIn.user?.name ?? 'ไม่ระบุชื่อผู้ใช้';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final dateStr = _formatDate(checkIn.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, ชื่อผู้เช็คอิน, เวลา
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
              ),
              subtitle: Text(
                dateStr,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Check-in',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Divider(),

            // พิกัด & ปุ่มดูเส้นทาง
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${checkIn.lat.toStringAsFixed(4)}  Lng: ${checkIn.lng.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapDetailPage(checkIn: checkIn),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF4F46E5)),
                    label: const Text(
                      'ดูเส้นทาง',
                      style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // แผนที่ Preview — กดเพื่อเปิดหน้าแผนที่เต็มจอ
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapDetailPage(checkIn: checkIn),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: latLng,
                          initialZoom: 14.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.appflutter.locationapp',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: latLng,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.indigo,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Overlay hint icon
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'ดูแผนที่',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (checkIn.description != null &&
                checkIn.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                checkIn.description!,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
