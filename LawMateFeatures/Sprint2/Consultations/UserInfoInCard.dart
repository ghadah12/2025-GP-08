import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoInCard extends StatefulWidget {
  final String name;
  final String type;
  final String description;
  final String docId;
  final String status;

  const UserInfoInCard({
    super.key,
    required this.name,
    required this.type,
    required this.description,
    required this.docId,
    required this.status,
  });

  @override
  State<UserInfoInCard> createState() => _UserInfoInCardState();
}

class _UserInfoInCardState extends State<UserInfoInCard> {
  bool _isButtonDisabled = false;
  String phoneNumber = '';
  String selectedCommunicationMethod = '';
  String selectedPrice = '';
  String? selectedLawyerUid;

  @override
  void initState() {
    super.initState();
    fetchExtraData();
  }

  Future<void> fetchExtraData() async {
    try {
      final consultationDoc = await FirebaseFirestore.instance
          .collection('Consultations')
          .doc(widget.docId)
          .get();

      if (consultationDoc.exists) {
        final userUid = consultationDoc['user_uid'];
        final data = consultationDoc.data()!;
        final price = data.containsKey('price') ? data['price'].toString() : '';
        final communicationMethod = data.containsKey('selectedCommunicationMethod')
            ? data['selectedCommunicationMethod'].toString()
            : '';
        final lawyerUid = data.containsKey('selected_lawyer_uid') ? data['selected_lawyer_uid'] : null;

        final userDoc = await FirebaseFirestore.instance
            .collection('Individual')
            .doc(userUid)
            .get();

        final phone = userDoc.data()!.containsKey('phone_number')
            ? userDoc['phone_number'].toString()
            : '';

        setState(() {
          selectedPrice = price;
          phoneNumber = phone;
          selectedCommunicationMethod = communicationMethod;
          selectedLawyerUid = lawyerUid;
        });
      }
    } catch (e) {
      debugPrint('Error fetching phone/price: $e');
    }
  }

  Future<void> markAsCompleted(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الإجراء'),
          content: const Text(
              'هل أنت متأكد من إنهاء الاستشارة؟\nلن تتمكن من التراجع عن هذا الإجراء بعد تأكيده.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('Consultations')
          .doc(widget.docId)
          .update({'status': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' تم إنهاء الاستشارة')),
      );

      setState(() {
        _isButtonDisabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFF917268),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 190,
              left: MediaQuery.of(context).size.width / 2 - 53.5,
              child: Container(
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
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 320,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Inter',
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 380,
              left: 20,
              right: 20,
              child: _infoBox('موضوع الإستشارة', widget.type),
            ),

            if (phoneNumber.isNotEmpty)
              Positioned(
                top: 450,
                left: 20,
                right: 20,
                child: _infoBox('رقم الجوال', phoneNumber),
              ),

            if (selectedCommunicationMethod.isNotEmpty)
              Positioned(
                top: 520,
                left: 20,
                right: 20,
                child: _infoBox('طريقة التواصل المفضلة', selectedCommunicationMethod),
              ),

            if ((selectedLawyerUid == null || selectedLawyerUid!.isEmpty) && selectedPrice.isNotEmpty)
              Positioned(
                top: 590,
                left: 20,
                right: 20,
                child: _infoBox('السعر المقترح', '$selectedPrice '),
              ),

            Positioned(
              top: selectedPrice.isNotEmpty && (selectedLawyerUid == null || selectedLawyerUid!.isEmpty) ? 660 : 590,
              left: 20,
              right: 20,
              child: _infoBox('الوصف', widget.description, height: 118),
            ),

            if (widget.status == 'accepted')
              Positioned(
                bottom: 40,
                left: 40,
                right: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isButtonDisabled ? null : () => markAsCompleted(context),
                  child: const Text(
                    '✅ تمت معالجة الطلب',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 25,
              left: 25,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, {double height = 54}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF062531),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.topRight,
        child: Text(
          '  $label : $value',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: 16,
            height: 1.5,
          ),

        ),
      ),
    );
  }
}
