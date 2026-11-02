import 'package:flutter/material.dart';

class AddDiaryScreen extends StatelessWidget {
  const AddDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Diary")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Diary Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              maxLines: 5,

              decoration: InputDecoration(
                labelText: "Description",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Class",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Student Name",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              height: 50,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text("Save Diary"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
