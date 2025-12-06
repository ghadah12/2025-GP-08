import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {


  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    _markNotificationsAsRead();
    super.dispose();
  }


  Future<void> _markNotificationsAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final unreadDocs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
        print(" تم تحديث الإشعارات عند الخروج");
      }
    } catch (e) {
      print(" خطأ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062531),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white)),
      ),
      body: currentUser == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text('لا توجد إشعارات', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final notificationsDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notificationsDocs.length,
            itemBuilder: (context, index) {
              final doc = notificationsDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'تنبيه';
              final String body = data['body'] ?? '';
              final Timestamp? timestamp = data['createdAt'];
              final bool isRead = data['isRead'] ?? true;

              final String formattedDate = timestamp != null
                  ? DateFormat('yyyy/MM/dd - hh:mm a').format(timestamp.toDate())
                  : 'الآن';

              return Card(
                color: const Color(0xFFA6847C),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Stack(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  title,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),


                    if (isRead == false)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Color(0xFF910E00),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5), // حدود بيضاء عشان تبرز
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
