import 'package:flutter/material.dart';

import 'parent_list_screen.dart';
import 'add_parent_screen.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  Widget card(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.family_restroom, color: Colors.blue, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Dashboard"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            card(
              context,
              "Parents",
              Icons.people,
              Colors.orange,
              const ParentListScreen(),
            ),
            card(
              context,
              "Add Parent",
              Icons.person_add,
              Colors.green,
              const AddParentScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
