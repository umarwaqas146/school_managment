import 'package:flutter/material.dart';

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Details")),

      body: const Padding(
        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "Holiday Announcement",

              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text(
              "School will remain closed tomorrow due to public holiday.",

              style: TextStyle(fontSize: 18),
            ),

            SizedBox(height: 20),

            Text("Date: 15 July 2026"),
          ],
        ),
      ),
    );
  }
}
