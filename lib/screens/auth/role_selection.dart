// import 'package:flutter/material.dart';

// import '../admin/dashboard/admin_dashboard.dart';
// import '../teacher/teacher_dashboard.dart';
// import '../student/student_dashboard.dart';
// import '../parent/parent_dashboard.dart';

// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Select Your Role"), centerTitle: true),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             const Text(
//               "Choose Your Role",
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.admin_panel_settings),
//                 label: const Text("Admin"),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const AdminDashboard(),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 15),

//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.school),
//                 label: const Text("Teacher"),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const TeacherDashboard(),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 15),

//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.person),
//                 label: const Text("Student"),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const StudentDashboard(),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 15),

//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.family_restroom),
//                 label: const Text("Parent"),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const ParentDashboard(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
