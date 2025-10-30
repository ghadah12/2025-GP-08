import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class MyRatingsPage extends StatefulWidget {

  final bool isLawyerView;

  const MyRatingsPage({
    Key? key,
    this.isLawyerView = false,
  }) : super(key: key);


  @override
  _MyRatingsPageState createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;


  Future<String> getLawyerName(String lawyerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('LegalProfessional')
          .doc(lawyerId)
          .get();
      if (doc.exists) {
        return doc.data()?['display_name'] ?? 'محامٍ غير معروف';
      }
    } catch (e) {
      print("Error fetching lawyer name: $e");
    }
    return 'محامٍ غير معروف';
  }


  Future<String> getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Individual')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data()?['display_name'] ?? 'مستخدم غير معروف';
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return 'مستخدم غير معروف';
  }


  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف',textAlign: TextAlign.right),
          content: const Text(
              'هل أنت متأكد من رغبتك في حذف هذا التقييم؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteRating(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRating(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('Ratings').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التقييم بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final queryField = widget.isLawyerView ? 'lawyer_id' : 'user_id';

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062531),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(

          widget.isLawyerView ? 'التقييمات' : 'تقييماتي',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('يرجى تسجيل الدخول لعرض البيانات'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Ratings')
            .where(queryField, isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ ما! تأكد من وجود الفهرس في Firestore'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(widget.isLawyerView ? 'لم تصلك أي تقييمات بعد.' : 'لم تقم بإضافة أي تقييمات بعد.'));
          }

          final ratingsDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: ratingsDocs.length,
            itemBuilder: (context, index) {
              final doc = ratingsDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String lawyerId = data['lawyer_id'] ?? '';
              final String userId = data['user_id'] ?? '';
              final double rating =
                  (data['rating'] as num?)?.toDouble() ?? 0.0;
              final String review = data['review'] ?? '';
              final Timestamp? timestamp = data['timestamp'];
              final String formattedDate = timestamp != null
                  ? DateFormat('yyyy/MM/dd')
                  .format(timestamp.toDate())
                  : 'بدون تاريخ';

              return Card(
                color: const Color(0xFFA6847C),
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          if (!widget.isLawyerView)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(doc.id);
                              },
                            )
                          else
                            const SizedBox(width: 48),


                          FutureBuilder<String>(
                            future: widget.isLawyerView ? getUserName(userId) : getLawyerName(lawyerId),
                            builder: (context, nameSnapshot) {
                              if (nameSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('جاري التحميل...',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16, color: Colors.white));
                              }
                              return Text(
                                nameSnapshot.data ?? 'غير معروف',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16, color: Colors.white),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 20.0,
                        itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {},
                        ignoreGestures: true,
                      ),
                      const SizedBox(height: 12),
                      if (review.isNotEmpty)
                        Text(
                          review,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 14, color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                            fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
