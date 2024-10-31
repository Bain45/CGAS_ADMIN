import 'package:cgas_admin/screen/dashboard_content.dart';
import 'package:cgas_admin/screen/manage_department.dart';
import 'package:cgas_admin/screen/manage_faculty.dart';
import 'package:cgas_admin/screen/manage_hod.dart';
import 'package:cgas_admin/screen/manage_security.dart';
import 'package:cgas_admin/screen/manage_year.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // To keep track of the selected index for navigation

  // Sidebar items
  List<String> _menuItems = ['Dashboard', 'Manage Security', 'Manage HOD', 'Manage Teacher', 'Manage Department', 'Manage Year'];

  // Function to switch between pages
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section: Logo and Menu Items
                  Column(
                    children: [
                      // Logo Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Image.asset(
                          'assets/Logo.png', // Add your logo here
                          width: 120,
                          height: 120,
                        ),
                      ),
                      // Sidebar Menu
                      Column(
                        children: _menuItems
                            .asMap()
                            .entries
                            .map((entry) => _buildMenuItem(entry.key, entry.value))
                            .toList(),
                      ),
                    ],
                  ),
                  // Bottom Section: Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.white),
                      title: Text('Logout', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        // Handle Logout
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content Area
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Top Bar
                Container(
                  color: Colors.blueGrey[50],
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _menuItems[_selectedIndex],
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blueGrey[900],
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text('Admin', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dashboard Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildContent(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build sidebar menu items
  Widget _buildMenuItem(int index, String title) {
    return ListTile(
      leading: Icon(
        _getIconForMenuItem(index),
        color: _selectedIndex == index ? Colors.blue : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.blue : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
    );
  }

  // Helper function to get icons for each menu item
  IconData _getIconForMenuItem(int menuItem) {
    switch (menuItem) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.shopping_bag;
      case 3:
        return Icons.shopping_cart;
      case 4:
        return Icons.settings;
      case 5:
        return Icons.date_range;
      default:
        return Icons.dashboard;
    }
  }

  // Helper function to build the content area
  Widget _buildContent(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return DashContent();
      case 1:
        return ManageSecurity();
      case 2:
        return ManageHOD();
      case 3:
        return ManageFaculty();
      case 4:
        return ManageDept();
      case 5:
        return ManageAcademicYear();
      default:
        return Center(child: Text("Dashboard"));
    }
  }
}