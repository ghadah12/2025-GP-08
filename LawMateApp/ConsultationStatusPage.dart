import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'ShawirRequestConsultation.dart';

class ConsultationStatusPage extends StatefulWidget {
  const ConsultationStatusPage({super.key});

  @override
  State<ConsultationStatusPage> createState() => _ConsultationStatusPageState();
}

class _ConsultationStatusPageState extends State<ConsultationStatusPage> {
  User? currentUser;
  String? userName;
  String? expandedConsultationId;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Individual')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc.data()?['display_name'] ?? '';
        });
      }
    }
  }

  Future<void> uploadFile(BuildContext context, String consultationId) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false, withReadStream: true);
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        final ref = FirebaseStorage.instance
            .ref()
            .child('consultation_files/$consultationId/$fileName');

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('Consultations')
            .doc(consultationId)
            .update({'file_url': downloadUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم رفع الملف بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في رفع الملف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول أولاً')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4E3DB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Consultations')
              .where('user_uid', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }

            try {
              final allDocs = snapshot.data!.docs;
              final consultations = allDocs.where((doc) {
                final ct = doc['created_time'];
                return ct != null && ct is Timestamp;
              }).toList();

              consultations.sort((a, b) {
                return (b['created_time'] as Timestamp)
                    .compareTo(a['created_time'] as Timestamp);
              });

              return Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF052532),
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 64),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'فَإِذَا عَزَمْتَ فَتَوَكَّلْ عَلَى اللَّهِ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (userName != null)
                          Text(
                            'مرحبًا، $userName',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: consultations.isEmpty
                          ? const Center(child: Text('لا يوجد'))
                          : ListView.builder(
                        itemCount: consultations.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final doc = consultations[index];
                          final docId = doc.id;
                          final type = doc['type']?.toString().trim();
                          final status = doc['status']?.toString().trim();

                          String statusText = '';
                          switch (status) {
                            case 'pending':
                              statusText = 'قيد الانتظار';
                              break;
                            case 'accepted':
                              statusText = 'تم القبول';
                              break;
                            case 'rejected':
                              statusText = 'تم الرفض';
                              break;
                            case 'completed':
                              statusText = 'تمت المعالجة';
                              break;
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                expandedConsultationId =
                                expandedConsultationId == docId ? null : docId;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA6847C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('نوع الاستشارة: ${type != null && type.isNotEmpty ? type : 'لا يوجد نوع استشارة'}'),
                                  Text('الحالة: $statusText', style: const TextStyle(color: Colors.white)),
                                  if (expandedConsultationId == docId) ...[
                                    const SizedBox(height: 10),
                                    if (status == 'accepted')
                                      GestureDetector(
                                        onTap: () => uploadFile(context, docId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "إرفاق الملفات",
                                            style: TextStyle(fontSize: 12, color: Colors.black),
                                          ),
                                        ),
                                      )
                                    else if (status == 'rejected')
                                      const Text(
                                        "نعتذر، لم يتم قبول طلب الاستشارة",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    else if (status == 'pending')
                                        const Text(
                                          "طلبك قيد الانتظار",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      else if (status == 'completed')
                                          const Text(
                                            "🎉 تم إنجاز الاستشارة بنجاح",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const Divider(thickness: 0.6),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShawirRequestConsultation()),
                      );
                      if (result == 'submitted') {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7D73),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(32),
                    ),
                    child: const Text("شاور", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            } catch (e) {
              return const Center(child: Text('❌ حدث خطأ أثناء معالجة البيانات'));
            }
          },
        ),
      ),
    );
  }
}
