import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'ShawirRequestConsultation.dart';
import 'rating.dart';


class ConsultationStatusPage extends StatefulWidget {
  const ConsultationStatusPage({super.key});

  @override
  State<ConsultationStatusPage> createState() => _ConsultationStatusPageState();
}

class _ConsultationStatusPageState extends State<ConsultationStatusPage> {
  User? currentUser;
  String? userName;
  String? expandedConsultationId;



  final List<TimeOfDay> _timeSlots = const [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
  ];


  String _fmtDateKey(DateTime d) => d.toIso8601String().split('T')[0];


  String _fmtTimeLabel(BuildContext context, TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }


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

  Future<void> uploadFiles(BuildContext context, String consultationId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: ['pdf','doc','docx','png','jpg','jpeg','heic','txt','ppt','pptx','xls','xlsx'],
      );

      if (result == null || result.files.isEmpty) return;

      final List<Map<String, dynamic>> uploaded = [];

      for (final f in result.files) {
        if (f.path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن رفع هذا الملف على هذا النظام.')),
          );
          continue;
        }

        final file = File(f.path!);
        final fileName = f.name;
        final mime = f.extension ?? '';
        final size = f.size;

        final ref = FirebaseStorage.instance
            .ref()
            .child('consultation_files/$consultationId/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        if (Navigator.canPop(context)) Navigator.pop(context);

        uploaded.add({
          'name': fileName,
          'url': url,
          'size': size,
          'mime': mime,
          'uploaded_at': FieldValue.serverTimestamp(),
          'uploader_uid': FirebaseAuth.instance.currentUser?.uid,
        });
      }

      if (uploaded.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('Consultations')
            .doc(consultationId)
            .set({
          'files': FieldValue.arrayUnion(uploaded),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم رفع ${uploaded.length} ملف/ملفات بنجاح')),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في رفع الملف: $e')),
      );
    }
  }


  Future<void> _openScheduleBottomSheetForConsultation(
      BuildContext context,
      DocumentSnapshot doc,
      ) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;


    final existingForConsultation = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('consultationId', isEqualTo: doc.id)
        .limit(1)
        .get();
    if (existingForConsultation.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد موعد سابق لهذه الاستشارة.')),
        );
      }
      return;
    }


    final data = doc.data() as Map<String, dynamic>? ?? {};
    final lawyerId = data['selected_lawyer_uid'] ??
        data['lawyerId'] ??
        data['selected_lawyer_id'];
    if (lawyerId == null || lawyerId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد محامٍ مرتبط بهذه الاستشارة.')),
      );
      return;
    }


    final apptsSnap = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .get();


    final Map<String, Map<String, dynamic>> dayMap = {};
    for (final d in apptsSnap.docs) {
      final m = d.data();
      final dateKey = (m['date'] ?? '').toString();
      if (dateKey.isEmpty) continue;

      final isHoliday = (m['isHoliday'] == true);
      dayMap.putIfAbsent(dateKey, () => {
        'blocked': <String>{},
        'holiday': false,
      });

      if (isHoliday) {
        dayMap[dateKey]!['holiday'] = true;
      } else {
        final timeLabel = (m['time'] ?? '').toString();
        if (timeLabel.isNotEmpty) {
          (dayMap[dateKey]!['blocked'] as Set<String>).add(timeLabel);
        }
      }
    }


    final today = DateTime.now();
    final last = today.add(const Duration(days: 30));
    final List<DateTime> availableDays = [];
    final Map<String, List<String>> availableTimesByDay = {};

    for (DateTime d = DateTime(today.year, today.month, today.day);
    !d.isAfter(last);
    d = d.add(const Duration(days: 1))) {
      final dateKey = _fmtDateKey(d);
      final isHoliday = (dayMap[dateKey]?['holiday'] == true);
      if (isHoliday) continue;

      final blocked = (dayMap[dateKey]?['blocked'] as Set<String>?) ?? <String>{};
      final freeTimes = <String>[];
      for (final t in _timeSlots) {
        final label = _fmtTimeLabel(context, t);
        if (!blocked.contains(label)) {
          freeTimes.add(label);
        }
      }
      if (freeTimes.isNotEmpty) {
        availableDays.add(d);
        availableTimesByDay[dateKey] = freeTimes;
      }
    }

    if (availableDays.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد تواريخ متاحة خلال 30 يومًا قادمة.')),
        );
      }
      return;
    }

    DateTime? selectedDate = availableDays.first;
    String? selectedTime;

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dateKey = _fmtDateKey(selectedDate!);
            final times = availableTimesByDay[dateKey] ?? [];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('حدد موعدك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  const Text('التواريخ المتاحة:'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: availableDays.map((d) {
                        final isSel = d.year == selectedDate!.year &&
                            d.month == selectedDate!.month &&
                            d.day == selectedDate!.day;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('${d.day}/${d.month}'),
                            selected: isSel,
                            onSelected: (_) {
                              setModalState(() {
                                selectedDate = d;
                                selectedTime = null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('الأوقات المتوفرة:'),
                  const SizedBox(height: 8),
                  if (times.isEmpty)
                    const Text('لا توجد أوقات متاحة لهذا اليوم')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: times.map((label) {
                        final isSel = label == selectedTime;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (_) {
                            setModalState(() {
                              selectedTime = label;
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedDate != null && selectedTime != null)
                          ? () async {
                        final dateStr = _fmtDateKey(selectedDate!);


                        final recheck = await FirebaseFirestore.instance
                            .collection('Appointments')
                            .where('consultationId', isEqualTo: doc.id)
                            .limit(1)
                            .get();
                        if (recheck.docs.isNotEmpty) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تحديد موعد سابق لهذه الاستشارة.')),
                            );
                          }
                          return;
                        }


                        final timeCheck = await FirebaseFirestore.instance
                            .collection('Appointments')
                            .where('lawyerId', isEqualTo: lawyerId)
                            .where('date', isEqualTo: dateStr)
                            .where('time', isEqualTo: selectedTime)
                            .limit(1)
                            .get();
                        if (timeCheck.docs.isNotEmpty) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('عذرًا، الوقت تم حجزه للتو. اختر وقتًا آخر.')),
                            );
                          }
                          return;
                        }


                        final apptRef = await FirebaseFirestore.instance
                            .collection('Appointments')
                            .add({
                          'lawyerId': lawyerId,
                          'userId': current!.uid,
                          'date': dateStr,
                          'time': selectedTime,
                          'isAvailable': false,
                          'isHoliday': false,
                          'consultationId': doc.id,
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });


                        await FirebaseFirestore.instance
                            .collection('Consultations')
                            .doc(doc.id)
                            .set({
                          'appointment': {
                            'id': apptRef.id,
                            'date': dateStr,
                            'time': selectedTime,
                            'lawyerId': lawyerId,
                            'userId': current.uid,
                          }
                        }, SetOptions(merge: true));

                        await FirebaseFirestore.instance.collection('notifications').add({
                          'recipientId': lawyerId,
                          'title': "تم تحديد موعد جديد! ",
                          'body': "قام العميل ${userName ?? 'مستخدم'} بحجز موعد بتاريخ $dateStr الساعة $selectedTime.",
                          'createdAt': FieldValue.serverTimestamp(),
                          'isRead': false,
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم حجز الموعد: $dateStr - $selectedTime')),
                          );
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B7D73),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('تأكيد الحجز', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                          final Timestamp timestamp = doc['created_time'];
                          final formattedDate = '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
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


                          final raw = doc.data();
                          final Map<String, dynamic> data = (raw is Map<String, dynamic>)
                              ? raw
                              : Map<String, dynamic>.from(raw as Map);


                          final Map<String, dynamic> appt = (data['appointment'] is Map)
                              ? Map<String, dynamic>.from(data['appointment'] as Map)
                              : <String, dynamic>{};

                          final bool hasAppointment = (appt['date'] != null && appt['time'] != null);
                          final String? apptDate = appt['date']?.toString();
                          final String? apptTime = appt['time']?.toString();



                          final lawyerName = doc['selected_lawyer_name']?.toString() ?? '';

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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 12, color: Colors.black),
                                      ),
                                      Text('نوع الاستشارة: ${type != null && type.isNotEmpty ? type : 'لا يوجد نوع استشارة'}'),
                                    ],
                                  ),

                                  if (lawyerName != null && lawyerName.isNotEmpty)
                                    Text(
                                      'المحامي: $lawyerName',
                                      style: const TextStyle(color: Colors.white),
                                    ),




                                  Text('الحالة: $statusText', style: const TextStyle(color: Colors.white)),


                                  if (hasAppointment) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'موعدك: ${apptDate ?? ''} - ${apptTime ?? ''}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],


                                  if (expandedConsultationId == docId) ...[
                                    const SizedBox(height: 10),
                                    if (status == 'accepted')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () => uploadFiles(context, docId),
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
                                          ),
                                          const SizedBox(width: 8),


                                          if (!hasAppointment)
                                            GestureDetector(
                                              onTap: () => _openScheduleBottomSheetForConsultation(context, doc),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(color: Colors.black),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "حدد موعدك",
                                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                border: Border.all(color: Colors.grey),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "تم تحديد موعد",
                                                style: TextStyle(fontSize: 12, color: Colors.black54),
                                              ),
                                            ),

                                        ],
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
                                      else if (status == 'completed') ...[
                                          const Text(
                                            "🎉 تم إنجاز الاستشارة بنجاح",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => RatingDialog(
                                                  consultationId: doc.id,
                                                  lawyerId: doc['selected_lawyer_uid'] ?? '',
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.star, color: Colors.amber),
                                            label: const Text('قيّم المحامي'),
                                          ),
                                        ],

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
