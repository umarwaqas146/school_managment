import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditStudentScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String docId;

  const EditStudentScreen({
    super.key,
    required this.studentData,
    required this.docId,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _cnicController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _classController;
  late final TextEditingController _sectionController;
  late final TextEditingController _addressController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: _value('studentName').isNotEmpty
          ? _value('studentName')
          : _value('name'),
    );

    _fatherNameController = TextEditingController(text: _value('fatherName'));

    _cnicController = TextEditingController(
      text: _value('cnic').isNotEmpty
          ? _value('cnic')
          : _value('bForm').isNotEmpty
          ? _value('bForm')
          : _value('cnicBForm'),
    );

    _emailController = TextEditingController(text: _value('email'));

    _phoneController = TextEditingController(text: _value('phone'));

    _studentIdController = TextEditingController(text: _value('studentId'));

    _classController = TextEditingController(text: _value('class'));

    _sectionController = TextEditingController(text: _value('section'));

    _addressController = TextEditingController(text: _value('address'));
  }

  String _value(String key) {
    final value = widget.studentData[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  String? _nameValidator(String? value, String fieldName) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$fieldName is required.';
    }

    if (text.length < 2) {
      return '$fieldName is too short.';
    }

    if (text.length > 60) {
      return '$fieldName is too long.';
    }

    final valid = RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(text);

    if (!valid) {
      return '$fieldName can contain letters and spaces only.';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required.';
    }

    final valid = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);

    if (!valid) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Phone number is required.';
    }

    final valid = RegExp(r'^03[0-9]{9}$').hasMatch(phone);

    if (!valid) {
      return 'Use Pakistani format: 03001234567';
    }

    return null;
  }

  String? _cnicValidator(String? value) {
    final cnic = value?.trim() ?? '';

    if (cnic.isEmpty) {
      return 'B-Form / CNIC is required.';
    }

    final valid = RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$').hasMatch(cnic);

    if (!valid) {
      return 'Use format: 12345-1234567-1';
    }

    return null;
  }

  Future<bool> _checkDuplicateEmail(String email) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Admin session expired. Please login again.');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .where('email', isEqualTo: email.toLowerCase())
        .get();

    return snapshot.docs.any((doc) => doc.id != widget.docId);
  }

  Future<bool> _checkDuplicatePhone(String phone) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Admin session expired. Please login again.');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .where('phone', isEqualTo: phone)
        .get();

    return snapshot.docs.any((doc) => doc.id != widget.docId);
  }

  Future<bool> _checkDuplicateCnic(String cnic) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Admin session expired. Please login again.');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .where('cnic', isEqualTo: cnic)
        .get();

    return snapshot.docs.any((doc) => doc.id != widget.docId);
  }

  Future<void> _updateStudent() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('Admin session expired. Please login again.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final name = _nameController.text.trim();
      final fatherName = _fatherNameController.text.trim();
      final cnic = _cnicController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final studentId = _studentIdController.text.trim();
      final className = _classController.text.trim();
      final section = _sectionController.text.trim();
      final address = _addressController.text.trim();

      final duplicateEmail = await _checkDuplicateEmail(email);

      if (duplicateEmail) {
        throw Exception('A student with this email already exists.');
      }

      final duplicatePhone = await _checkDuplicatePhone(phone);

      if (duplicatePhone) {
        throw Exception('A student with this phone number already exists.');
      }

      final duplicateCnic = await _checkDuplicateCnic(cnic);

      if (duplicateCnic) {
        throw Exception('A student with this B-Form / CNIC already exists.');
      }

      final studentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .doc(widget.docId);

      await studentRef.update({
        'studentName': name,
        'name': name,
        'fatherName': fatherName,
        'cnic': cnic,
        'email': email,
        'phone': phone,
        'studentId': studentId,
        'class': className,
        'section': section,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully.')),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(e.message ?? 'Unable to update student.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1769E0), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: _decoration(label, icon, hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF102A43)),
        title: const Text(
          'Edit Student',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 30,
              24,
              isMobile ? 16 : 30,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),
                      const SizedBox(height: 20),
                      _buildFormCard(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Student Profile',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Update the student information and save the latest record.',
          style: const TextStyle(color: Color(0xFF627D98), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information', Icons.person_outline_rounded),
          const SizedBox(height: 18),
          _responsiveFields(isMobile, [
            _field(
              controller: _nameController,
              label: 'Student Name',
              icon: Icons.person_outline_rounded,
              validator: (value) => _nameValidator(value, 'Student name'),
            ),
            _field(
              controller: _fatherNameController,
              label: 'Father Name',
              icon: Icons.family_restroom_outlined,
              validator: (value) => _nameValidator(value, 'Father name'),
            ),
            _field(
              controller: _cnicController,
              label: 'B-Form / CNIC',
              icon: Icons.badge_outlined,
              hint: '12345-1234567-1',
              validator: _cnicValidator,
              keyboardType: TextInputType.number,
            ),
            _field(
              controller: _studentIdController,
              label: 'Student ID',
              icon: Icons.fingerprint_rounded,
              validator: (value) => _requiredValidator(value, 'Student ID'),
            ),
          ]),
          const SizedBox(height: 28),
          _sectionTitle('Contact Information', Icons.contact_phone_outlined),
          const SizedBox(height: 18),
          _responsiveFields(isMobile, [
            _field(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            _field(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone_outlined,
              hint: '03001234567',
              keyboardType: TextInputType.phone,
              validator: _phoneValidator,
            ),
            _field(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              validator: (value) => _requiredValidator(value, 'Address'),
            ),
          ]),
          const SizedBox(height: 28),
          _sectionTitle('Academic Information', Icons.school_outlined),
          const SizedBox(height: 18),
          _responsiveFields(isMobile, [
            _field(
              controller: _classController,
              label: 'Class',
              icon: Icons.class_outlined,
              validator: (value) => _requiredValidator(value, 'Class'),
            ),
            _field(
              controller: _sectionController,
              label: 'Section',
              icon: Icons.grid_view_rounded,
              validator: (value) => _requiredValidator(value, 'Section'),
            ),
          ]),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE1E8EF)),
          const SizedBox(height: 20),
          _buildActions(isMobile),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF1769E0)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _responsiveFields(bool isMobile, List<Widget> fields) {
    if (isMobile) {
      return Column(
        children: fields
            .map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: field,
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: fields.map((field) {
        return SizedBox(width: 460, child: field);
      }).toList(),
    );
  }

  Widget _buildActions(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _updateStudent,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _updateStudent,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save Changes'),
        ),
      ],
    );
  }
}
