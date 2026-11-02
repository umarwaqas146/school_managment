import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Application"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                const Icon(Icons.school, size: 90, color: Colors.blue),

                const SizedBox(height: 20),

                const Text(
                  "The Sapient School",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "School Management System",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),

                const Divider(height: 40),

                buildTile(Icons.info, "Version", "1.0.0"),

                buildTile(Icons.code, "Developed By", "Muhammad Umar Waqas"),

                buildTile(
                  Icons.school,
                  "University",
                  "COMSATS University Islamabad",
                ),

                buildTile(Icons.computer, "Department", "BS Computer Science"),

                buildTile(Icons.storage, "Backend", "Firebase"),

                buildTile(Icons.phone_android, "Framework", "Flutter"),

                buildTile(Icons.language, "Programming Language", "Dart"),

                const SizedBox(height: 30),

                const Text(
                  "© 2026 The Sapient School\nAll Rights Reserved",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
