import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/home_page.dart';
import '../pages/location_page.dart';
import '../pages/map_page.dart';
import '../pages/about_page.dart';
import '../pages/login_page.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final ApiService _apiService = ApiService();

  AppDrawer({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบบัญชีนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _apiService.logout();
              Get.offAll(() => LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // ==============================
          // MODERN DRAWER HEADER
          // ==============================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x223730A3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Where Am I',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live Location & Friend Sharing',
                  style: TextStyle(
                    color: Colors.indigo.shade100,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ==============================
          // DRAWER NAVIGATION LIST
          // ==============================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: 'ฟีดเช็คอิน (Home)',
                  subtitle: 'รายการกิจกรรมล่าสุดของเพื่อน',
                  onTap: () {
                    Get.back();
                    Get.offAll(() => const HomePage(initialIndex: 0));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_rounded,
                  title: 'เพื่อนที่ใช้งาน (Friends)',
                  subtitle: 'ค้นหาและจัดการรายชื่อเพื่อน',
                  onTap: () {
                    Get.back();
                    Get.offAll(() => const HomePage(initialIndex: 1));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: 'โปรไฟล์ของฉัน (Profile)',
                  subtitle: 'จัดการบัญชีและประวัติเช็คอิน',
                  onTap: () {
                    Get.back();
                    Get.offAll(() => const HomePage(initialIndex: 2));
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  icon: Icons.my_location_rounded,
                  title: 'แชร์ตำแหน่งของฉัน',
                  subtitle: 'ดูพิกัด GPS ปัจจุบันและแชร์',
                  onTap: () {
                    Get.back();
                    Get.to(() => LocationPage());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.map_rounded,
                  title: 'แผนที่รวม (Interactive Map)',
                  subtitle: 'ดูหมุดเช็คอินทั้งหมดบนแผนที่',
                  onTap: () {
                    Get.back();
                    Get.to(() => MapPage());
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: 'เกี่ยวกับระบบ (About)',
                  subtitle: 'ข้อมูลและเวอร์ชันของแอป',
                  onTap: () {
                    Get.back();
                    Get.to(() => AboutPage());
                  },
                ),
              ],
            ),
          ),

          // ==============================
          // LOGOUT FOOTER BUTTON
          // ==============================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: InkWell(
              onTap: () => _confirmLogout(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'ออกจากระบบ (Logout)',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
