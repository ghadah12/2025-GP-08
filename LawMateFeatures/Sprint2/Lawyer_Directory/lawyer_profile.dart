import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LawyerProfile extends StatefulWidget {
  final String lawyerId;

  const LawyerProfile({super.key, required this.lawyerId});

  @override
  State<LawyerProfile> createState() => _LawyerProfileState();
}

class _LawyerProfileState extends State<LawyerProfile> {
  Map<String, dynamic>? lawyerData;
  String userType = '';
  String currentState = '';
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchLawyerData();
    fetchCurrentUserType();
  }

  Future<void> fetchLawyerData() async {
    final doc = await FirebaseFirestore.instance
        .collection('LegalProfessional')
        .doc(widget.lawyerId)
        .get();

    if (doc.exists) {
      setState(() {
        lawyerData = doc.data();
        currentState = lawyerData?['state'] ?? '';
      });
    }
  }

  Future<void> fetchCurrentUserType() async {
    final docUser = await FirebaseFirestore.instance
        .collection('Individual')
        .doc(currentUserId)
        .get();

    if (docUser.exists) {
      setState(() {
        userType = docUser.data()?['userType'] ?? '';
      });
    } else {
      final docLawyer = await FirebaseFirestore.instance
          .collection('LegalProfessional')
          .doc(currentUserId)
          .get();

      setState(() {
        userType = docLawyer.data()?['userType'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lawyerData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062531),
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 107,
              height: 107,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/lawyer-svgrepo-com.svg',
                  width: 60,
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lawyerData?['display_name'] ?? 'اسم المحامي',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              width: 250,
              height: 2,
              color: const Color(0xFF917268),
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                children: [
                  _infoRow('assets/icons/building.svg',
                      'المدينة: ${lawyerData?['city'] ?? ''}'),
                  const SizedBox(height: 30),
                  _infoRow('assets/icons/license-svgrepo-com (2).svg',
                      'رقم رخصة المحاماة: ${lawyerData?['lawlicense'] ?? ''}'),
                  const SizedBox(height: 30),
                  _infoRow('assets/icons/balance.svg',
                      'التخصص: ${lawyerData?['specialties']?.join("، ") ?? ''}'),
                  const SizedBox(height: 30),
                  _infoRow('assets/icons/Saudi_Riyal_Symbol-2.svg',
                      'سعر الاستشارة: ${lawyerData?['price'] ?? ''}'),
                  const SizedBox(height: 24),
                ],
              ),
            ),


            if (userType == 'legalProfessional')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusButton(context, 'متاح', const Color(0xFF9C7A6B)),
                  const SizedBox(width: 16),
                  _statusButton(context, 'مشغول', const Color(0xFFB0A39A)),
                ],
              ),

            const SizedBox(height: 24),


            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Ratings')
                  .where('lawyer_id', isEqualTo: widget.lawyerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("لا يوجد تقييمات بعد",
                      style: TextStyle(fontSize: 16));
                }

                final docs = snapshot.data!.docs;
                final average = docs
                    .map((d) => (d['rating'] as num))
                    .reduce((a, b) => a + b) / docs.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'متوسط التقييم: ⭐ ${average.toStringAsFixed(1)} من 5',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final review = docs[index]['review']?.toString() ?? '';
                          final rating = docs[index]['rating'] ?? 0;
                          final date =
                          (docs[index]['timestamp'] as Timestamp?)?.toDate();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.star, color: Colors.amber),
                              title: Text('$rating نجوم'),
                              subtitle: review.isNotEmpty
                                  ? Text(review)
                                  : const Text("بدون تعليق"),
                              trailing: date != null
                                  ? Text(
                                "${date.day}/${date.month}/${date.year}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),



            const SizedBox(height: 24),
            if (userType == 'legalProfessional')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statusButton(context, 'متاح', const Color(0xFF9C7A6B)),
                  const SizedBox(width: 16),
                  _statusButton(context, 'مشغول', const Color(0xFFB0A39A)),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String iconPath, String label) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF062531),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 4,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                iconPath,
                color: Colors.white,
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(BuildContext context, String label, Color color) {
    bool isCurrent = (currentState == 'available' && label == 'متاح') ||
        (currentState == 'busy' && label == 'مشغول');

    return GestureDetector(
      onTap: isCurrent
          ? null
          : () async {
        String newState = label == 'متاح' ? 'available' : 'busy';
        await FirebaseFirestore.instance
            .collection('LegalProfessional')
            .doc(widget.lawyerId)
            .update({'state': newState});
        setState(() {
          currentState = newState;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF917268).withOpacity(0.6) : const Color(0xFF917268),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
