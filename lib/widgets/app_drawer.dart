import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/location_page.dart';
import '../pages/map_page.dart';
import '../pages/about_page.dart';
import '../pages/login_page.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  'Where Am I',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Get.back();
              Get.offAll(() => HomePage());
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Get.back();
              Get.offAll(() => ProfilePage());
            },
          ),
          ListTile(
            leading: Icon(Icons.my_location),
            title: Text('Location'),
            onTap: () {
              Get.back();
              Get.offAll(() => LocationPage());
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Map'),
            onTap: () {
              Get.back();
              Get.offAll(() => MapPage());
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              Get.back();
              Get.offAll(() => AboutPage());
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _apiService.logout();
              Get.offAll(() => LoginPage());
            },
          ),
        ],
      ),
    );
  }
}
