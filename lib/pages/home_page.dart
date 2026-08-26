import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'feed_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FeedPage(),
    const Center(
      child: Text(
        'เพื่อนที่ใช้งาน (Coming Soon)',
        style: TextStyle(fontSize: 18),
      ),
    ),
    ProfilePage(),
  ];

  final List<String> _titles = ['เพื่อนอยู่ไหน?', 'เพื่อนที่ใช้งาน', 'โปรไฟล์'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _user = user;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user info',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo),
        centerTitle: false,
      ),
      drawer: AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'ฟีดเช็คอิน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'เพื่อนที่ใช้งาน',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
