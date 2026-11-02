import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolProfileScreen extends StatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController schoolNameController = TextEditingController();

  final TextEditingController principalController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("school_profile")
          .doc("profile")
          .set({
            "schoolName": schoolNameController.text.trim(),
            "principal": principalController.text.trim(),
            "phone": phoneController.text.trim(),
            "email": emailController.text.trim(),
            "address": addressController.text.trim(),
            "updatedAt": Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("School Profile Saved Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  Widget buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) =>
            value == null || value.isEmpty ? "Required Field" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    schoolNameController.dispose();
    principalController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField(schoolNameController, "School Name", Icons.school),

              buildField(principalController, "Principal Name", Icons.person),

              buildField(phoneController, "Phone Number", Icons.phone),

              buildField(emailController, "Email", Icons.email),

              buildField(
                addressController,
                "Address",
                Icons.location_on,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Save Profile",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
