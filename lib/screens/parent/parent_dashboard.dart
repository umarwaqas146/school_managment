import 'package:flutter/material.dart';
import '../admin/parents/parent_list_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Dashboard"), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,

          children: [
            _card(
              context,
              "Parents",
              Icons.family_restroom,
              const ParentListScreen(),
            ),

            _simpleCard("Children", Icons.school),

            _simpleCard("Attendance", Icons.check_circle),

            _simpleCard("Results", Icons.assignment),

            _simpleCard("Fee", Icons.account_balance_wallet),

            _simpleCard("Profile", Icons.account_circle),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },

      child: Card(
        elevation: 5,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 45, color: Colors.blue),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleCard(String title, IconData icon) {
    return Card(
      elevation: 5,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, size: 45, color: Colors.blue),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
