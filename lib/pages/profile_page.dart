import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../widgets/check_in_dialog.dart';
import 'login_page.dart';
import 'map_detail_page.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  final bool showAppBar;

  const ProfilePage({super.key, this.showAppBar = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  List<LocationModel> _myCheckIns = [];
  int _friendsCount = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Settings switches
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 1. Fetch user data
      final user = await _apiService.getCurrentUser();
      
      // 2. Fetch my check-ins
      List<LocationModel> checkIns = [];
      try {
        checkIns = await _apiService.getCheckIns(my: true);
      } catch (_) {
        checkIns = [];
      }

      // 3. Fetch friends count
      int friendsCount = 0;
      try {
        final friends = await _storageService.getFriends();
        friendsCount = friends.length;
      } catch (_) {
        friendsCount = 0;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _myCheckIns = checkIns;
          _friendsCount = friendsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);
    final bioController = TextEditingController(text: _user!.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'แก้ไขข้อมูลโปรไฟล์',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ-นามสกุล / ชื่อแสดง',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'คำอธิบายตัวเอง (Bio)',
                hintText: 'เช่น ชอบท่องเที่ยว, สำรวจสถานที่ใหม่ๆ',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newBio = bioController.text.trim();
                  if (newName.isNotEmpty) {
                    setState(() {
                      _user = _user!.copyWith(
                        name: newName,
                        bio: newBio.isEmpty ? null : newBio,
                      );
                    });
                    Navigator.pop(ctx);
                    Get.snackbar(
                      'สำเร็จ',
                      'อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว',
                      backgroundColor: Colors.green.shade600,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyCheckInsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded, color: Colors.indigo, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ประวัติการเช็คอินของฉัน',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${_myCheckIns.length} รายการ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _myCheckIns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'ยังไม่มีประวัติการเช็คอิน',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openCheckInDialog();
                            },
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('เช็คอินตอนนี้เลย'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _myCheckIns.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _myCheckIns[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            child: const Icon(Icons.pin_drop, color: Colors.indigo),
                          ),
                          title: Text(
                            item.locationName ?? 'ตำแหน่งที่แชร์',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description != null && item.description!.isNotEmpty)
                                Text(
                                  item.description!,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                item.createdAt.isNotEmpty
                                    ? item.createdAt.split('T').first
                                    : 'ไม่ระบุวันที่',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(ctx);
                            Get.to(() => MapDetailPage(checkIn: item));
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCheckInDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const CheckInDialog(),
    ).then((_) => _loadProfileData());
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.security, color: Colors.indigo),
            SizedBox(width: 10),
            Text('ความปลอดภัยของบัญชี', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSecurityItem(Icons.lock_outline, 'การเข้ารหัสข้อมูล', 'เปิดใช้งาน SSL/TLS เข้ารหัส 256-bit'),
            const SizedBox(height: 12),
            _buildSecurityItem(Icons.verified_user_outlined, 'สถานะความปลอดภัย', 'เชื่อมต่อกับเซิร์ฟเวอร์หลักปลอดภัย'),
            const SizedBox(height: 12),
            _buildSecurityItem(Icons.key, 'Token Authentication', 'ใช้งาน JSON Web Token (JWT)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.indigo.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpCenterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Colors.indigo),
            SizedBox(width: 10),
            Text('ศูนย์ช่วยเหลือ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📌 วิธีการใช้งาน Where Am I:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            Text('1. ฟีดเช็คอิน: ดูตำแหน่งกิจกรรมล่าสุดของเพื่อนๆ ในระบบ', style: TextStyle(fontSize: 13)),
            SizedBox(height: 4),
            Text('2. เพื่อนที่ใช้งาน: ค้นหาและบันทึกรายชื่อเพื่อนที่คุณสนใจ', style: TextStyle(fontSize: 13)),
            SizedBox(height: 4),
            Text('3. แผนที่: ตรวจสอบพิกัด GPS บนแผนที่แบบ Interactive', style: TextStyle(fontSize: 13)),
            SizedBox(height: 4),
            Text('4. โปรไฟล์: ดูสถิติการเช็คอินและจัดการข้อมูลส่วนตัว', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('เข้าใจแล้ว', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.indigo),
            SizedBox(width: 10),
            Text('เกี่ยวกับ Where Am I', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, size: 48, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            const Text(
              'Where Am I (MyMap)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.2.0 • Stable Release',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            const Text(
              'แอปพลิเคชันสำหรับการแชร์ตำแหน่งและเช็คอินสถานที่ร่วมกับเพื่อนๆ พร้อมแสดงผลบนแผนที่แบบ Real-time',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red),
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
              backgroundColor: Colors.red.shade600,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'โปรไฟล์ของฉัน',
                style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.indigo),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProfileData,
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: Colors.indigo,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text('กำลังโหลดข้อมูลโปรไฟล์...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    if (_hasError && _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่สามารถโหลดข้อมูลโปรไฟล์ได้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfileData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String userName = _user?.name.isNotEmpty == true ? _user!.name : 'ผู้ใช้งาน Where Am I';
    final String userEmail = _user?.email ?? 'ยังไม่มีการระบุอีเมล';
    final String userBio = _user?.bio?.isNotEmpty == true ? _user!.bio! : '📍 สมาชิกชุมชน Where Am I แผนที่และเช็คอิน';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ==============================
          // 1. TOP PROFILE HERO BANNER
          // ==============================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x223F51B5),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              children: [
                // Avatar with Verified badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name & Verified Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.amberAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 4),

                // Email
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE0E7FF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),

                // Bio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userBio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Edit Profile Button
                ElevatedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'แก้ไขโปรไฟล์',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4338CA),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==============================
          // 2. STATS CARDS SECTION
          // ==============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'เช็คอินทั้งหมด',
                    value: '${_myCheckIns.length}',
                    icon: Icons.pin_drop_rounded,
                    color: Colors.blue.shade600,
                    onTap: _showMyCheckInsSheet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'เพื่อนของฉัน',
                    value: '$_friendsCount',
                    icon: Icons.people_alt_rounded,
                    color: Colors.indigo.shade600,
                    onTap: () {
                      Get.offAll(() => const HomePage(initialIndex: 1));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'สถานะบัญชี',
                    value: 'ปกติ',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF10B981),
                    onTap: _showSecurityDialog,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==============================
          // 3. QUICK ACTION BUTTONS
          // ==============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.add_location_alt_rounded,
                      label: 'เช็คอินด่วน',
                      color: Colors.indigo,
                      onTap: _openCheckInDialog,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.history_rounded,
                      label: 'ประวัติเช็คอิน',
                      color: Colors.blue.shade700,
                      onTap: _showMyCheckInsSheet,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'ค้นหาเพื่อน',
                      color: Colors.teal.shade700,
                      onTap: () {
                        Get.offAll(() => const HomePage(initialIndex: 1));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==============================
          // 4. ACCOUNT SETTINGS SECTION
          // ==============================
          _buildSectionTitle('การจัดการบัญชี'),
          _buildSettingsGroup([
            _buildSettingsTile(
              icon: Icons.badge_outlined,
              title: 'ข้อมูลส่วนตัว',
              subtitle: 'ชื่อ, อีเมล, Bio ข้อมูลส่วนบุคคล',
              onTap: _showEditProfileDialog,
            ),
            _buildSettingsTile(
              icon: Icons.security_rounded,
              title: 'ความปลอดภัยและความเป็นส่วนตัว',
              subtitle: 'การเชื่อมต่อ SSL และการยืนยันตัวตน',
              onTap: _showSecurityDialog,
            ),
          ]),

          const SizedBox(height: 16),

          // ==============================
          // 5. PREFERENCES & CONTROLS
          // ==============================
          _buildSectionTitle('การตั้งค่าและการแจ้งเตือน'),
          _buildSettingsGroup([
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'การแจ้งเตือนกิจกรรม',
              subtitle: 'รับการแจ้งเตือนเมื่อเพื่อนเช็คอินใกล้เคียง',
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                Get.snackbar(
                  'การตั้งค่า',
                  val ? 'เปิดการแจ้งเตือนเรียบร้อย' : 'ปิดการแจ้งเตือนแล้ว',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
            _buildSwitchTile(
              icon: Icons.share_location_rounded,
              title: 'แชร์ตำแหน่งแบบ Real-time',
              subtitle: 'อนุญาตให้เพื่อนในระบบค้นหาตำแหน่งของคุณ',
              value: _locationSharingEnabled,
              onChanged: (val) {
                setState(() => _locationSharingEnabled = val);
                Get.snackbar(
                  'การตั้งค่า',
                  val ? 'เปิดแชร์ตำแหน่ง Real-time แล้ว' : 'ปิดแชร์ตำแหน่ง Real-time แล้ว',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ==============================
          // 6. SUPPORT & INFO
          // ==============================
          _buildSectionTitle('ช่วยเหลือและข้อมูล'),
          _buildSettingsGroup([
            _buildSettingsTile(
              icon: Icons.help_center_outlined,
              title: 'ศูนย์ช่วยเหลือและการใช้งาน',
              subtitle: 'คู่มือวิธีใช้งานระบบแผนที่และการเช็คอิน',
              onTap: _showHelpCenterDialog,
            ),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'เกี่ยวกับแอปพลิเคชัน',
              subtitle: 'Where Am I v1.2.0 Stable',
              onTap: _showAboutDialog,
            ),
          ]),

          const SizedBox(height: 24),

          // ==============================
          // 7. LOGOUT BUTTON
          // ==============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey.shade100),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF4F46E5),
        onChanged: onChanged,
      ),
    );
  }
}
