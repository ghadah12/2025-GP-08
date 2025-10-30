import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingDialog extends StatefulWidget {
  final String consultationId;
  final String lawyerId;

  const RatingDialog({
    required this.consultationId,
    required this.lawyerId,
    Key? key,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double selectedRating = 3.0;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('قيّم المحامي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: selectedRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              selectedRating = rating;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reviewController,
            decoration: const InputDecoration(
              hintText: 'اكتب مراجعتك (اختياري)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // إغلاق النافذة بدون حفظ
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('Ratings')
                .doc('${widget.consultationId}_${FirebaseAuth.instance.currentUser!.uid}')
                .set({
              'consultation_id': widget.consultationId,
              'lawyer_id': widget.lawyerId,
              'user_id': FirebaseAuth.instance.currentUser!.uid,
              'rating': selectedRating,
              'review': reviewController.text.trim(),
              'timestamp': FieldValue.serverTimestamp(),
            });

            Navigator.pop(context); // إغلاق النافذة بعد الحفظ
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال تقييمك بنجاح ✅')),
            );
          },
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
