import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'NotificationService.dart';
import 'HomePage.dart';


class WaitingApproved extends StatefulWidget {
  const WaitingApproved({super.key});

  @override
  State<WaitingApproved> createState() => _WaitingApprovedState();
}

class _WaitingApprovedState extends State<WaitingApproved> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _startListeningForApproval();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }


  void _startListeningForApproval() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('LegalProfessional')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {


      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['is_approved'] == true) {

          NotificationService.showNotification(
            title: "!أهلاً بك في LawMate",
            body: "تهانينا! تمت الموافقة على حسابك كمحامي، يمكنك الآن استقبال الاستشارات.",
          );

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
            );
          }
        }
      }

      else {

        NotificationService.showNotification(
          title: " طلب الانضمام كمحام",
          body: "نعتذر، لم يتم قبولك لعدم استيفاء شروط التسجيل المطلوبة.",
        );


        if (mounted) {
          FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Beige_and_Brown_Aesthetic_Background_Instagram_Story2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                onPressed: () {

                  Navigator.of(context).pop();
                },
              ),
            ),
            const Spacer(flex: 2),
            const Center(
              child: Text(
                '! تم أستلام طلبك',
                style: TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'شكرًا لتسجيلك! سيتم مراجعة طلبك خلال 72 ساعة. في حال الموافقة، ستتمكن من تسجيل الدخول. نقدر صبرك وتفهمك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
