import 'package:flutter/material.dart';
import 'UserSignIn.dart';
import 'LawyerSign.dart';

class SignUpUserLawyer extends StatelessWidget {
  const SignUpUserLawyer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/images/Pastel Colors Organic Aesthetic Minimalist Modern Motivational Q.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 النص القرآني
          Align(
            alignment: const Alignment(0.0, -0.37),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'وَإِذَا حَكَمْتُمْ بَيْنَ النَّاسِ أَنْ تَحْكُمُوا بِالْعَدْلِ إِنَّ اللَّهَ نِعِمَّا يَعِظُكُمْ بِهِ إِنَّ اللَّهَ كَانَ سَمِيعًا بَصِيرًا',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.black87,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // 🔹 الأزرار
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 290),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserSignIn()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4E3DB),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text('سجل دخول كمستخدم'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LawyerSign()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4E3DB),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text('سجل دخول كمحامي'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
