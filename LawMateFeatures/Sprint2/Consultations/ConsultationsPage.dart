import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserInfoInCard.dart';
import 'lawyer_profile.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  String selectedStatus = 'pending';

  final Map<String, String> statusLabels = {
    'all': 'الكل',
    'pending': 'قيد الانتظار',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
    'completed': 'تمت المعالجة',
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4E3DB),
        body: Stack(
          children: [
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: 370,
                color: const Color(0xFF052532),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () {
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LawyerProfile(lawyerId: currentUserId),
                                ),
                              );
                            }
                          },
                        ),

                        const Text(
                          'الاستشارات',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(3.1416),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedStatus,
                      dropdownColor: const Color(0xFF062531),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: statusLabels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value, textAlign: TextAlign.right),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Consultations')
                          .where('target_lawyers', arrayContains: currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: _NoRequestsCard());
                        }

                        final allRequests = snapshot.data!.docs;
                        final currentUser = FirebaseAuth.instance.currentUser;

                        final filtered = allRequests.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'];
                          final selectedLawyer = data['selected_lawyer_uid'];
                          final rejectedBy = data.containsKey('rejected_by') ? List<String>.from(data['rejected_by']) : <String>[];
                          final currentUid = currentUser?.uid;

                          if (selectedLawyer != null && selectedLawyer != currentUid) {
                            return false;
                          }

                          if (selectedStatus == 'all') {
                            return (status == 'pending' &&
                                (selectedLawyer == null || selectedLawyer == currentUid) &&
                                !rejectedBy.contains(currentUid)) ||
                                (status == 'accepted' && selectedLawyer == currentUid) ||
                                (status == 'completed' && selectedLawyer == currentUid) ||
                                (status == 'rejected' && rejectedBy.contains(currentUid));
                          }

                          if (selectedStatus == 'completed') {
                            return status == 'completed' && selectedLawyer == currentUid;
                          }

                          if (selectedStatus == 'rejected') {
                            return status == 'rejected' && rejectedBy.contains(currentUid);
                          }

                          if (selectedStatus == 'accepted') {
                            return status == 'accepted' && selectedLawyer == currentUid;
                          }

                          if (selectedStatus == 'pending') {
                            return status == 'pending' &&
                                (selectedLawyer == null || selectedLawyer == currentUid) &&
                                !rejectedBy.contains(currentUid);
                          }

                          return false;
                        }).toList();

                        // 👇👇👇 الإضافة الجديدة هنا: كود الترتيب 👇👇👇
                        // يرتب القائمة بحيث يكون الوقت الأحدث (b) قبل الوقت الأقدم (a)
                        filtered.sort((a, b) {
                          Timestamp timeA = a['created_time'];
                          Timestamp timeB = b['created_time'];
                          return timeB.compareTo(timeA); // تنازلي (الأحدث في الأعلى)
                        });
                        // 👆👆👆 نهاية الإضافة 👆👆👆

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 30),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final userUid = doc['user_uid'];
                            final docId = doc.id;

                            final Timestamp timestamp = doc['created_time'];
                            final formattedDate = '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';


                            final isEven = index % 2 == 0;
                            final backgroundColor = isEven ? const Color(0xFFF4E3DB) : const Color(0xFF9B7D73);
                            final textColor = isEven ? Colors.black : Colors.white;

                            final type = doc.data().toString().contains('type') ? doc['type'] : '';
                            final description = doc.data().toString().contains('description') &&
                                doc['description'] != null &&
                                doc['description'].toString().trim().isNotEmpty
                                ? doc['description'].toString()
                                : 'لا يوجد وصف';
                            final status = doc['status'];
                            final rejectedBy = doc.data().toString().contains('rejected_by')
                                ? List<String>.from(doc['rejected_by'])
                                : <String>[];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('Individual').doc(userUid).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) return const SizedBox();
                                final name = userSnapshot.data!['display_name'] ?? 'مستخدم';

                                return _ConsultationCard(
                                  name: name,
                                  backgroundColor: backgroundColor,
                                  textColor: textColor,
                                  status: status,
                                  rejectedBy: rejectedBy,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserInfoInCard(
                                          name: name,
                                          type: type,
                                          description: description,
                                          docId: docId,
                                          status: status,
                                        ),
                                      ),
                                    );
                                  },
                                  onAccept: () => updateConsultationStatus(docId, 'accepted', userUid, type),
                                  onReject: () => updateConsultationStatus(docId, 'rejected', userUid, type),
                                  type: type,
                                  createdAt: formattedDate,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print("Error sending notification: $e");
    }
  }


  void updateConsultationStatus(String docId, String status, String userUid, String consultationType) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;


    final lawyerSnap = await FirebaseFirestore.instance
        .collection('LegalProfessional')
        .doc(currentUser.uid)
        .get();
    final lawyerName = lawyerSnap.data()?['display_name'] ?? 'محامٍ';

    final String unifiedTitle = "تحديث حالة طلب استشارة: $consultationType";


    if (status == 'accepted') {
      await FirebaseFirestore.instance.collection('Consultations').doc(docId).update({
        'status': 'accepted',
        'selected_lawyer_uid': currentUser.uid,
        'selected_lawyer_name': lawyerName,
      });


      await sendNotification(
          recipientId: userUid,
          title: unifiedTitle,
          body: "وافق المحامي $lawyerName على طلب الاستشارة. "
      );


    } else if (status == 'rejected') {
      await FirebaseFirestore.instance.collection('Consultations').doc(docId).update({
        'status': 'rejected',
        'rejected_by': FieldValue.arrayUnion([currentUser.uid])
      });


      await sendNotification(
          recipientId: userUid,
          title: unifiedTitle,
          body: " اعتذر المحامي $lawyerName عن قبول طلبك في الوقت الحالي. "
      );
    }
  }
}

class _ConsultationCard extends StatelessWidget {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final String status;
  final List<String> rejectedBy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;
  final String type;
  final String createdAt;

  const _ConsultationCard({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.status,
    required this.rejectedBy,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
    required this.type,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'الاسم: $name',
                  style: TextStyle(
                    fontSize: 20,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),


              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'موضوع الاستشارة: $type',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تاريخ إنشاء الطلب: $createdAt',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (status == 'pending' && !rejectedBy.contains(currentUid)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton('رفض', onReject),
                    _actionButton('قبول', onAccept),
                  ],
                ),
              ] else ...[
                Center(
                  child: Text(
                    status == 'accepted'
                        ? 'تم القبول'
                        : status == 'completed'
                        ? 'تمت المعالجة'
                        : 'تم الرفض',
                    style: const TextStyle(
                      color: Color(0xFF052532),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF052532),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NoRequestsCard extends StatelessWidget {
  const _NoRequestsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: 300,
        height: 150,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF9B7D73),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Text(
            'لا توجد طلبات حالياً',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
