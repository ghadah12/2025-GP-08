import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FindLawyerHomePage.dart';

class ShawirRequestConsultation extends StatefulWidget {
  const ShawirRequestConsultation({super.key});

  @override
  State<ShawirRequestConsultation> createState() => _ShawirRequestConsultationState();
}

class _ShawirRequestConsultationState extends State<ShawirRequestConsultation> {
  int currentStep = 0;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? selectedCategory;
  bool forAllLawyers = false;
  bool forSpecificLawyer = false;
  bool isAgreed = false;
  String? selectedLawyer;
  List<String> lawyerNames = [];
  bool hasShownPopup = false;
  String? selectedLawyerDisplay;
  String? selectedLawyerId;




  final List<String> categories = [
    'قوانين الأسرة',
    'عقود الإيجار',
    'مخالفات المرور'
  ];

  @override
  void initState() {
    super.initState();
    fetchLawyers();


  }

  void fetchLawyers() async {
    final snapshot = await FirebaseFirestore.instance.collection('LegalProfessional').get();
    setState(() {
      lawyerNames = snapshot.docs.map((doc) => doc['display_name'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF917268),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('شاور', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 40),
                  buildStepRow(
                    step: 1,
                    title: 'تصنيف الاستشارة',
                    subtitle: 'اختر نوع التصنيف',
                    onTap: () => setState(() => currentStep = 1),
                    showLine: currentStep >= 1,
                  ),
                  if (currentStep == 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(right: 38, left: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF062531),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          hint: const Text(
                            'اختر التصنيف',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          dropdownColor: const Color(0xFF062531),
                          items: categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(right: 38),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF062531),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setState(() => currentStep = 2),
                          child: const Text('التالي'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  buildStepRow(
                    step: 2,
                    title: 'وصف الاستشارة',
                    subtitle: 'وضح تفاصيل طلبك ليسهل على المحامي فهمه',
                    onTap: () => setState(() => currentStep = 2),
                    showLine: currentStep >= 2,
                  ),
                  if (currentStep == 2) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 90,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF062531),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.topRight,
                      margin: const EdgeInsets.only(right: 38, left: 15),
                      child: TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'الوصف',
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(right: 38),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => setState(() => currentStep = 1),
                            child: const Text('السابق'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF062531),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => setState(() => currentStep = 3),
                            child: const Text('التالي'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  buildStepRow(
                    step: 3,
                    title: 'اختيار المحامي',
                    subtitle: '',
                    onTap: () => setState(() => currentStep = 3),
                    showLine: false,
                  ),
                  if (currentStep == 3) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF062531),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(top: 10, right: 38, left: 15),
                      child: CheckboxListTile(
                        value: forAllLawyers,
                        onChanged: (value) {
                          setState(() {
                            forAllLawyers = value ?? false;
                            if (forAllLawyers) {
                              forSpecificLawyer = false;
                              if (!hasShownPopup) {
                                hasShownPopup = true;
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: AlertDialog(
                                        title: const Text('ملاحظة'),
                                        content: const Text(
                                          'هذا الخيار يعني ترسل طلبك وبإمكان أي محامٍ الاطلاع على التفاصيل وقبول الاستشارة إذا كان السعر مناسبًا له',
                                          textAlign: TextAlign.right,
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('حسنًا'),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            }
                          });
                        },
                        title: const Text('لكل المحامين', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    if (forAllLawyers)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(right: 10, top: 3, left: 10),
                        margin: const EdgeInsets.only(top: 10, bottom: 10, right: 38, left: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF062531),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: priceController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'سعر الاستشارة',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF062531),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(top: 10, right: 38, left: 15),
                      child: CheckboxListTile(
                        value: forSpecificLawyer,
                        onChanged: (value) => setState(() {
                          forSpecificLawyer = value ?? false;
                          if (forSpecificLawyer) forAllLawyers = false;
                        }),
                        title: const Text('اختيار محامي محدد', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    if (forSpecificLawyer) ...[
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FindLawyerHomePage()),
                          );

                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              selectedLawyerDisplay = result['name'];
                              selectedLawyerId = result['id'];
                            });
                          }
                        },


                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10, right: 38, left: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF062531),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            textDirection: TextDirection.rtl,
                            children: const [
                              Text(
                                'اختر محامي',
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.right,
                              ),
                            
                            ],
                          ),

                        ),
                      ),
                      if (selectedLawyerDisplay != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(right: 38, left: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF052532),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedLawyerDisplay!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],


                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'أوافق على مشاركة الملفات والمعلومات مع المحامي دون أدنى مسؤولية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Checkbox(
                          value: isAgreed,
                          onChanged: (value) => setState(() => isAgreed = value ?? false),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => setState(() => currentStep = 2),
                          child: const Text('السابق'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF062531),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isAgreed
                              ? () async {
                            if (selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء اختيار تصنيف الاستشارة', textAlign: TextAlign.center)),
                              );
                              return;
                            }
                            if (descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء كتابة وصف الاستشارة', textAlign: TextAlign.center)),
                              );
                              return;
                            }
                            if (!forAllLawyers && !forSpecificLawyer) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء اختيار "لكل المحامين" أو "محامي محدد"', textAlign: TextAlign.center)),
                              );
                              return;
                            }
                            if (forAllLawyers && priceController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء إدخال سعر الاستشارة', textAlign: TextAlign.center)),
                              );
                              return;
                            }
                            if (forSpecificLawyer && (selectedLawyerId == null || selectedLawyerId!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء اختيار اسم المحامي', textAlign: TextAlign.center)),
                              );
                              return;
                            }


                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null || user.isAnonymous) return;

                            await FirebaseFirestore.instance.collection('Consultations').add({
                              'type': selectedCategory ?? '',
                              'description': descriptionController.text.trim(),
                              'price': forAllLawyers ? priceController.text.trim() : null,
                              'selected_lawyer_name': forSpecificLawyer ? selectedLawyerDisplay ?? '' : null,
                              'selected_lawyer_id': forSpecificLawyer ? selectedLawyerId ?? '' : null,
                              'user_uid': user.uid,
                              'status': 'pending',
                              'created_time': FieldValue.serverTimestamp(),
                              'file_url': null,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم إرسال الطلب بنجاح',
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(milliseconds: 1500),
                                backgroundColor: Color(0xFF062531),
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1500));
                            Navigator.pop(context);
                          }
                              : null,
                          child: const Text('إرسال الطلب'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCircleWithNumber(String number, {bool showLine = true}) {
    return Column(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 4),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        if (showLine)
          Container(
            width: 2,
            height: 35,
            margin: const EdgeInsets.only(top: 6),
            color: const Color(0xFF062531),
          )
      ],
    );
  }

  Widget buildStepRow({
    required int step,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showLine,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        buildCircleWithNumber('$step', showLine: showLine),
        const SizedBox(width: 10),
      ],
    );
  }
}
