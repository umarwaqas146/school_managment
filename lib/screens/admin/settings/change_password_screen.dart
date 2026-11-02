import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool obscure3 = true;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: "no-user",
          message: "No logged in user found",
        );
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password Changed Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Password Change Failed")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget passwordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Required Field";
          }

          if (label == "New Password" && value.length < 6) {
            return "Minimum 6 characters";
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              passwordField(
                currentPasswordController,
                "Current Password",
                obscure1,
                () {
                  setState(() {
                    obscure1 = !obscure1;
                  });
                },
              ),

              passwordField(
                newPasswordController,
                "New Password",
                obscure2,
                () {
                  setState(() {
                    obscure2 = !obscure2;
                  });
                },
              ),

              passwordField(
                confirmPasswordController,
                "Confirm Password",
                obscure3,
                () {
                  setState(() {
                    obscure3 = !obscure3;
                  });
                },
              ),

              const SizedBox(height: 20),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text(
                          "Change Password",
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
