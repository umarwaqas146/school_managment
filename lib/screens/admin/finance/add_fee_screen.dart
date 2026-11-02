import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddFeeScreen extends StatefulWidget {
  const AddFeeScreen({super.key});

  @override
  State<AddFeeScreen> createState() => _AddFeeScreenState();
}

class _AddFeeScreenState extends State<AddFeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final studentController = TextEditingController();
  final classController = TextEditingController();
  final amountController = TextEditingController();
  final monthController = TextEditingController();

  bool isLoading = false;

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? validateStudentName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Student name is required';
    }

    if (text.length < 2) {
      return 'Student name must be at least 2 characters';
    }

    if (text.length > 100) {
      return 'Student name is too long';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(text)) {
      return 'Student name can contain letters and spaces only';
    }

    return null;
  }

  String? validateClass(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Class is required';
    }

    if (text.length > 50) {
      return 'Class name is too long';
    }

    if (!RegExp(r'^[a-zA-Z0-9\s-]+$').hasMatch(text)) {
      return 'Invalid class format';
    }

    return null;
  }

  String? validateAmount(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Fee amount is required';
    }

    final amount = double.tryParse(text);

    if (amount == null) {
      return 'Enter a valid numeric amount';
    }

    if (amount <= 0) {
      return 'Fee amount must be greater than 0';
    }

    if (amount > 10000000) {
      return 'Fee amount is too large';
    }

    if (amount.toString().contains('.') &&
        text.split('.').length == 2 &&
        text.split('.')[1].length > 2) {
      return 'Amount can have maximum 2 decimal places';
    }

    return null;
  }

  String? validateMonth(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Fee month is required';
    }

    if (text.length > 30) {
      return 'Fee month is too long';
    }

    if (!RegExp(r'^[a-zA-Z0-9\s/-]+$').hasMatch(text)) {
      return 'Invalid month format';
    }

    return null;
  }

  // ============================================================
  // DUPLICATE CHECK
  // ============================================================

  Future<bool> isDuplicateFee() async {
    final studentName = studentController.text.trim().toLowerCase();
    final className = classController.text.trim().toLowerCase();
    final month = monthController.text.trim().toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('fees')
        .where('studentNameLower', isEqualTo: studentName)
        .where('classLower', isEqualTo: className)
        .where('monthLower', isEqualTo: month)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ============================================================
  // SAVE FEE
  // ============================================================

  Future<void> saveFee() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final duplicate = await isDuplicateFee();

      if (duplicate) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fee for this student, class and month already exists',
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      final studentName = studentController.text.trim();
      final className = classController.text.trim();
      final month = monthController.text.trim();
      final amount = double.parse(amountController.text.trim());

      final feeRef = FirebaseFirestore.instance.collection('fees').doc();

      await feeRef.set({
        'feeId': feeRef.id,
        'studentName': studentName,
        'studentNameLower': studentName.toLowerCase(),
        'class': className,
        'classLower': className.toLowerCase(),
        'amount': amount,
        'month': month,
        'monthLower': month.toLowerCase(),
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      studentController.clear();
      classController.clear();
      amountController.clear();
      monthController.clear();

      _formKey.currentState?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to add fee';

      if (e.code == 'permission-denied') {
        message = 'You do not have permission to add a fee';
      } else if (e.code == 'unavailable') {
        message = 'Server is temporarily unavailable. Please try again';
      } else if (e.code == 'failed-precondition') {
        message = 'Firestore index is required for this operation';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add fee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
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

  // ============================================================
  // FORM FIELD
  // ============================================================

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: inputDecoration(label: label, hint: hint, icon: icon),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    studentController.dispose();
    classController.dispose();
    amountController.dispose();
    monthController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Add Fee',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              color: Colors.blue.shade700,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Enter valid student fee details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      buildField(
                        controller: studentController,
                        label: 'Student Name',
                        hint: 'Enter student name',
                        icon: Icons.person_outline,
                        validator: validateStudentName,
                      ),

                      buildField(
                        controller: classController,
                        label: 'Class',
                        hint: 'Enter class',
                        icon: Icons.class_outlined,
                        validator: validateClass,
                      ),

                      buildField(
                        controller: amountController,
                        label: 'Fee Amount',
                        hint: 'Enter fee amount',
                        icon: Icons.payments_outlined,
                        validator: validateAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      buildField(
                        controller: monthController,
                        label: 'Fee Month',
                        hint: 'e.g. September 2026',
                        icon: Icons.calendar_month_outlined,
                        validator: validateMonth,
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : saveFee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.blue.shade200,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isLoading ? 'Saving...' : 'Save Fee',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
