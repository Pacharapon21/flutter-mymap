import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<FriendModel> _friends = [];
  Map<int, LocationModel> _latestCheckIns = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _storageService.getFriends();
      final friendIds = friends.map((f) => f.id).toList();
      final checkIns = await _apiService.getLatestCheckInsForFriends(friendIds);
      setState(() {
        _friends = friends;
        _latestCheckIns = checkIns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบเพื่อน', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบ "${friend.name}" ออกจากรายชื่อเพื่อนใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.removeFriend(friend.id);
      _loadData();
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddFriendDialog(
        apiService: _apiService,
        storageService: _storageService,
        existingFriendIds: _friends.map((f) => f.id).toList(),
        onFriendAdded: () {
          Navigator.pop(ctx);
          _loadData();
        },
      ),
    );
  }

  String _formatLastSeen(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'เพิ่งเช็คอิน';
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
      if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  Color _getActivityColor(String? createdAt) {
    if (createdAt == null) return Colors.grey.shade300;
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inHours < 1) return Colors.green;
      if (diff.inHours < 24) return Colors.orange;
      return Colors.grey.shade400;
    } catch (_) {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F51B5)))
          : _friends.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFF3F51B5),
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 100),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      return _buildFriendCard(_friends[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'เพิ่มเพื่อน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_outlined, size: 52, color: Colors.indigo.shade300),
          ),
          const SizedBox(height: 20),
          const Text(
            'ยังไม่มีเพื่อน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3250),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เพิ่มเพื่อน" เพื่อค้นหาและเพิ่มเพื่อนที่\nสมัครใช้งานแล้ว',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('เพิ่มเพื่อนตอนนี้'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(FriendModel friend) {
    final checkIn = _latestCheckIns[friend.id];
    final activityColor = _getActivityColor(checkIn?.createdAt);
    final initial = friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?';

    return Dismissible(
      key: Key('friend_${friend.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_remove, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('ลบเพื่อน', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _removeFriend(friend);
        return false; // let _loadData handle the refresh
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8EAF6),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: activityColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3250),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (checkIn != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13, color: Colors.indigo.shade300),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              checkIn.locationName ?? 'เช็คอินแล้ว',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            _formatLastSeen(checkIn.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        'ยังไม่มีการเช็คอิน',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade300, size: 22),
                onPressed: () => _removeFriend(friend),
                tooltip: 'ลบเพื่อน',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// Dialog: ค้นหาและเพิ่มเพื่อน
// ================================================================
class _AddFriendDialog extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final List<int> existingFriendIds;
  final VoidCallback onFriendAdded;

  const _AddFriendDialog({
    required this.apiService,
    required this.storageService,
    required this.existingFriendIds,
    required this.onFriendAdded,
  });

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _message = null;
    });

    try {
      final results = await widget.apiService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _searchResults = [];
        _message = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        _isSuccess = false;
      });
    }
  }

  Future<void> _addFriend(UserModel user) async {
    final friend = FriendModel(
      id: user.id,
      name: user.name,
      addedAt: DateTime.now(),
    );

    final added = await widget.storageService.addFriend(friend);
    setState(() {
      _message = added ? 'เพิ่ม "${user.name}" เป็นเพื่อนแล้ว! 🎉' : '"${user.name}" อยู่ในรายชื่อเพื่อนแล้ว';
      _isSuccess = added;
    });

    if (added) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) widget.onFriendAdded();
    }
  }

  bool _isFriend(int userId) => widget.existingFriendIds.contains(userId);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_search, color: Color(0xFF3F51B5), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ค้นหาเพื่อน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3250),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'พิมพ์ชื่อของผู้ใช้ที่สมัครแล้ว',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ชื่อผู้ใช้...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3F51B5)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                            _message = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 10),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ค้นหา', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            // Message feedback
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isSuccess ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                      size: 16,
                      color: _isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results list
            if (_hasSearched && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'ผลการค้นหา',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final alreadyFriend = _isFriend(user.id);
                    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

                    return Container(
                      decoration: BoxDecoration(
                        color: alreadyFriend ? Colors.grey.shade50 : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyFriend ? Colors.grey.shade200 : Colors.indigo.shade100,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: alreadyFriend
                              ? Colors.grey.shade200
                              : const Color(0xFFE8EAF6),
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: alreadyFriend ? Colors.grey : const Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: alreadyFriend ? Colors.grey : const Color(0xFF2D3250),
                          ),
                        ),
                        subtitle: alreadyFriend
                            ? const Text('เป็นเพื่อนกันแล้ว', style: TextStyle(fontSize: 11))
                            : null,
                        trailing: alreadyFriend
                            ? Icon(Icons.check_circle, color: Colors.green.shade400, size: 22)
                            : ElevatedButton(
                                onPressed: () => _addFriend(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F51B5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text('เพิ่ม', style: TextStyle(fontSize: 13)),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_hasSearched && _searchResults.isEmpty) ...[
              const SizedBox(height: 14),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่พบผู้ใช้ที่ตรงกัน',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    Text(
                      'ลองพิมพ์ชื่อที่ผู้ใช้ลงทะเบียนไว้',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
