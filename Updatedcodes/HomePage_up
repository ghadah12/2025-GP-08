import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logOut.dart';
import 'ConsultationStatusPage.dart';
import 'ConsultationsPage.dart'; // استيراد الصفحة الجديدة

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String routeName = '/homePage';

  Future<bool> isIndividualUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('Individual')
        .doc(currentUser.uid)
        .get();

    return userDoc.exists;
  }

  Future<bool> isLawyerUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('LegalProfessional')
        .doc(currentUser.uid)
        .get();

    return userDoc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062531),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 190.0, left: 90.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 180),

              // زر الإعدادات
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, LogOutPage.routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA6847C),
                  minimumSize: const Size(230, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                    side: const BorderSide(width: 1),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'الإعدادات',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter Tight',
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // زر استشاراتي لليوزر العادي
              FutureBuilder<bool>(
                future: isIndividualUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == false) {
                    return const SizedBox();
                  }

                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConsultationStatusPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA6847C),
                      minimumSize: const Size(230, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                        side: const BorderSide(width: 1),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'استشاراتي',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter Tight',
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // زر طلبات الاستشارة للمحامي فقط
              FutureBuilder<bool>(
                future: isLawyerUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == false) {
                    return const SizedBox();
                  }

                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  const ConsultationsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA6847C),
                      minimumSize: const Size(230, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                        side: const BorderSide(width: 1),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'طلبات الاستشارة',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter Tight',
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
