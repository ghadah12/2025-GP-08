import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'ConsultationStatusPage.dart';
import 'ConsultationsPage.dart';
import 'logOut.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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

  Future<String> fetchFirstName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '';

    final userDoc = await FirebaseFirestore.instance
        .collection('Individual')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      String fullName = userDoc.data()?['display_name'] ?? '';
      return fullName.split(' ').first;
    }

    final lawyerDoc = await FirebaseFirestore.instance
        .collection('LegalProfessional')
        .doc(currentUser.uid)
        .get();

    if (lawyerDoc.exists) {
      String fullName = lawyerDoc.data()?['display_name'] ?? '';
      return fullName.split(' ').first;
    }

    return '';
  }

  Future<int> fetchCompletedConsultations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;

    final isLawyer = await isLawyerUser();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Consultations')
        .where(
      isLawyer ? 'selected_lawyer_uid' : 'user_uid',
      isEqualTo: currentUser.uid,
    )
        .where('status', isEqualTo: 'completed')
        .get();


    return querySnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF062531),
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([
            isIndividualUser(),
            isLawyerUser(),
            fetchFirstName(),
            fetchCompletedConsultations(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final bool isIndividual = snapshot.data![0];
            final bool isLawyer = snapshot.data![1];
            final String firstName = snapshot.data![2];
            final int completedCount = snapshot.data![3];

            List<String> titles = isLawyer
                ? ['التقييمات', 'طلبات الاستشارة']
                : ['الدليل قانوني', 'استشاراتي'];

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Whiteandgreysimplewelcomeaugustflyer2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, left: 30),
                    child: GestureDetector(
                      onTap: () {},
                      child: SvgPicture.asset(
                        'assets/icons/notification-13-svgrepo-com.svg',
                        width: 45,
                        height: 45,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0,
                  right: size.width * 0.02,
                  child: Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Gold_modern_and_minimalist_for_law_firm_templateremovebgpreview1.png'),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.12,
                  right: size.width * 0.08,
                  child: Text(
                    'مرحبًا $firstName',
                    style: TextStyle(
                      color: Color(0xFFEFECE8),
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (isLawyer)
                  Positioned(
                    top: size.height * 0.28,
                    left: size.width * 0.08,
                    right: size.width * 0.08,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF062531),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/trophy-svgrepo-com.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'إنجازاتك',
                                  style: TextStyle(
                                    color: Color(0xFFEFECE8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'عدد الاستشارات المنجزة: $completedCount',
                              style: TextStyle(
                                color: Color(0xFFEFECE8),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ...List.generate(titles.length, (index) {
                  final bool isLeft = index % 2 == 0;
                  final double topOffset = isLawyer
                      ? (index < 2 ? size.height * 0.42 : size.height * 0.6)
                      : (index < 2 ? size.height * 0.40 : size.height * 0.58);
                  final double horizontalOffset = size.width * 0.08;

                  return Positioned(
                    top: topOffset,
                    left: isLeft ? horizontalOffset : null,
                    right: !isLeft ? horizontalOffset : null,
                    child: GestureDetector(
                      onTap: () {
                        if (titles[index] == 'استشاراتي') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ConsultationStatusPage()));
                        } else if (titles[index] == 'طلبات الاستشارة') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ConsultationsPage()));
                        }
                      },
                      child: buildCard(
                        title: titles[index],
                        subtitle: (!isLawyer && index == 0) || (isLawyer && titles[index] == 'التقييمات') ? 'قريباً' : null,
                      ),
                    ),
                  );
                }),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: buildBottomNavigation(context, isLawyer),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildCard({required String title, String? subtitle}) {
    return Container(
      width: 160,
      height: 170,
      decoration: BoxDecoration(
        color: Color.fromRGBO(155, 125, 115, 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigation(BuildContext context, bool isLawyer) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Color(0xFF062531),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20,
            left: size.width * 0.18,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, HomePage.routeName);
              },
              child: buildIconButton('assets/icons/home-svgrepo-com.svg'),
            ),
          ),
          Positioned(
            top: 23,
            right: size.width * 0.18,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, LogOutPage.routeName);
              },
              child: buildIconButton('assets/icons/settings-cog-svgrepo-com.svg'),
            ),
          ),
          if (!isLawyer)
            Positioned(
              top: -25,
              left: size.width * 0.5 - 35,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/bot-svgrepo-com.svg',
                    color: Color(0xFF005A4F),
                    width: 50,
                    height: 50,
                    semanticsLabel: 'Bot Icon',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildIconButton(String assetPath) {
    return Container(
      width: 40,
      height: 40,
      child: SvgPicture.asset(
        assetPath,
        semanticsLabel: 'icon',
        color: Colors.white,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}
