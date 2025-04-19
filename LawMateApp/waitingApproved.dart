import 'package:flutter/material.dart';

class WaitingApproved extends StatelessWidget {
  const WaitingApproved({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/userlawyer.jpg'),
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
                  Navigator.pushReplacementNamed(context, '/signUpUserLawyer');
                },
              ),
            ),
            const Spacer(flex: 2),
            Center(
              child: Text(
                '! تم أستلام طلبك',
                style: const TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'شكرًا لتسجيلك! سيتم مراجعة طلبك خلال 72 ساعة. في حال الموافقة، ستتمكن من تسجيل الدخول. نقدر صبرك وتفهمك.',
                textAlign: TextAlign.center,
                style: const TextStyle(
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
