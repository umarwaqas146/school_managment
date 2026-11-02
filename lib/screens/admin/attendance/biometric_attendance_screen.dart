import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAttendanceScreen extends StatefulWidget {
  const BiometricAttendanceScreen({super.key});

  @override
  State<BiometricAttendanceScreen> createState() =>
      _BiometricAttendanceScreenState();
}

class _BiometricAttendanceScreenState extends State<BiometricAttendanceScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  bool verified = false;

  Future<void> scanFingerprint() async {
    try {
      bool result = await auth.authenticate(
        localizedReason: "Scan fingerprint",

        options: const AuthenticationOptions(biometricOnly: true),
      );

      setState(() {
        verified = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? "Fingerprint Verified" : "Verification Failed",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Biometric Attendance"),

        centerTitle: true,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              Icons.fingerprint,

              size: 120,

              color: verified ? Colors.green : Colors.blue,
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: scanFingerprint,

              icon: const Icon(Icons.fingerprint),

              label: const Text("Scan Fingerprint"),
            ),
          ],
        ),
      ),
    );
  }
}
