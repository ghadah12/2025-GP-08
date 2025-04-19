import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'waitingApproved.dart';

class LawyerSignup extends StatefulWidget {
  final String email;
  final String username;
  final String password;

  const LawyerSignup({
    super.key,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  State<LawyerSignup> createState() => _LawyerSignupState();
}

class _LawyerSignupState extends State<LawyerSignup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  List<String?> _specialties = [null];
  String? _uploadedImageUrl;
  String? _uploadedFileUrl;

  final List<String> _allSpecialties = [
    'قوانين الأسرة',
    'عقود الإيجار',
    'مخالفات المرور',
  ];

  Future<void> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final ref = FirebaseStorage.instance.ref().child('lawyer_licenses/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        _uploadedFileUrl = url;
      });
    }
  }

  Future<void> registerLawyer() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      String uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('LegalProfessional').doc(uid).set({
        'uid': uid,
        'email': widget.email,
        'display_name': widget.username,
        'phone_number': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'specialties': _specialties.whereType<String>().toList(),
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
        'lawlicense': _licenseController.text.trim(),
        'license_file_url': _uploadedFileUrl ?? '',
        'photo_url': _uploadedImageUrl ?? '',
        'created_time': Timestamp.now(),
        'is_approved': false,
        'userType': 'legalProfessional',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم إنشاء الحساب بنجاح')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WaitingApproved()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' خطأ أثناء إنشاء الحساب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062531),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/userlawyer.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(15, 30),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _uploadedImageUrl != null
                        ? NetworkImage(_uploadedImageUrl!)
                        : const AssetImage('assets/images/hk.jpeg') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'رقم الجوال',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _cityController,
                        label: 'المدينة',
                        keyboardType: TextInputType.text,
                      ),

                      _buildTextField(
                        controller: _priceController,
                        label: 'سعر الأستشارة',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        controller: _licenseController,
                        label: 'رقم رخصة المحاماة',
                        keyboardType: TextInputType.text,
                      ),
                      ..._specialties.asMap().entries.map((entry) {
                        final index = entry.key;
                        final selected = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selected,
                                  decoration: _inputDecoration(label: 'التخصص'),
                                  items: _allSpecialties.map((spec) {
                                    final isSelected = _specialties.contains(spec);
                                    final isCurrent = spec == selected;
                                    return DropdownMenuItem(
                                      value: isSelected && !isCurrent ? null : spec,
                                      enabled: !isSelected || isCurrent,
                                      child: Text(
                                        spec,
                                        style: TextStyle(
                                          color: isSelected && !isCurrent ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _specialties[index] = value),
                                ),
                              ),
                              if (_specialties.length > 1)
                                IconButton(
                                  onPressed: () => setState(() => _specialties.removeAt(index)),
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_specialties.length < 3)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: TextButton.icon(
                                  onPressed: () => setState(() => _specialties.add(null)),
                                  icon: const Icon(Icons.add, color: Colors.brown),
                                  label: const Text('إضافة تخصص آخر', style: TextStyle(color: Colors.brown)),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: TextButton.icon(
                                onPressed: pickAndUploadFile,
                                icon: const Icon(Icons.attach_file, color: Colors.brown),
                                label: const Text('إرفاق ملف (اختياري)', style: TextStyle(color: Colors.brown)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            registerLawyer();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA6847C),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: const Text('إنشاء الحساب', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: _inputDecoration(label: label),
        validator: (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
    );
  }
}
