import 'package:flutter/material.dart';

class DashContent extends StatelessWidget {
  const DashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      childAspectRatio: 1.5,
      crossAxisCount: 4,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        _buildDashboardCard(Icons.people, 'Total Users', '1,234'),
        _buildDashboardCard(Icons.shopping_bag, 'Products', '542'),
        _buildDashboardCard(Icons.shopping_cart, 'Orders', '128'),
        _buildDashboardCard(Icons.monetization_on, 'Revenue', '\$12,345'),
      ],
    );
  }

  Widget _buildDashboardCard(IconData icon, String title, String data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: Colors.blueGrey[900]),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              data,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}