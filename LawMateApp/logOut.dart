import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogOutPage extends StatefulWidget {
  const LogOutPage({super.key});

  static const String routeName = '/logOut';

  @override
  State<LogOutPage> createState() => _LogOutPageState();
}

class _LogOutPageState extends State<LogOutPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool isDarkMode = false;
  bool notificationsEnabled = false;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (currentUser != null) {
      var doc = await FirebaseFirestore.instance
          .collection("Individual")
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        doc = await FirebaseFirestore.instance
            .collection("LegalProfessional")
            .doc(currentUser!.uid)
            .get();
      }

      final data = doc.data();
      if (data != null) {
        _emailController.text = data['email'] ?? '';
        _nameController.text = data['username'] ?? data['display_name'] ?? '';
        setState(() {
          isDarkMode = data['isDarkMode'] ?? false;
          notificationsEnabled = data['notifications'] ?? false;
        });
      }
    }
  }

  Future<void> saveChanges() async {
    final name = _nameController.text.trim();

    if (currentUser != null) {
      final uid = currentUser!.uid;

      String collection = 'Individual';
      var doc = await FirebaseFirestore.instance.collection(collection).doc(uid).get();

      if (!doc.exists) {
        collection = 'LegalProfessional';
        doc = await FirebaseFirestore.instance.collection(collection).doc(uid).get();
      }

      if (doc.exists) {
        try {
          await FirebaseFirestore.instance.collection(collection).doc(uid).update({
            'display_name': name,
            'isDarkMode': isDarkMode,
            'notifications': notificationsEnabled,
          });

          await currentUser!.updateDisplayName(name);
          await FirebaseAuth.instance.currentUser!.reload();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم حفظ التعديلات بنجاح")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(' حدث خطأ: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9D7D6C),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 27.0, left: 15.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF9D7D6C),
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'الملف الشخصي',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  buildTextField("البريد الإلكتروني", _emailController, enabled: false),
                  const SizedBox(height: 12),
                  buildTextField("اسم المستخدم", _nameController),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'الإعدادات',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  buildSwitchTile("الإشعارات", notificationsEnabled, (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  }),
                  const SizedBox(height: 12),
                  buildSwitchTile("المظهر", isDarkMode, (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D7D6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D7D6C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              child: const Text(
                'تسجيل خروج',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, textAlign: TextAlign.right)),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFE5E8EC),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, textAlign: TextAlign.right),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF9D7D6C),
        ),
      ],
    );
  }
}
