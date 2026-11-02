import 'package:flutter/material.dart';

class DiaryDetailsScreen extends StatelessWidget {
  const DiaryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diary Details")),

      body: const Padding(
        padding: EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "Math Homework",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text(
              "Complete Chapter 5 Questions 1-10",
              style: TextStyle(fontSize: 18),
            ),

            SizedBox(height: 20),

            Text("Student: Ali"),

            Text("Class: 10"),

            Text("Date: 15 July 2026"),
          ],
        ),
      ),
    );
  }
}
