import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerProfilePage extends StatelessWidget {
  final String lawyerId;

  const LawyerProfilePage({super.key, required this.lawyerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text('Lawyer Profile'),
        backgroundColor: const Color(0xFF062531),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('LegalProfessional').doc(lawyerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Lawyer data not found."));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: data['photo_url'] != null && data['photo_url'] != ''
                        ? NetworkImage(data['photo_url'])
                        : const AssetImage('assets/images/hk.jpeg') as ImageProvider,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data['display_name'] ?? 'No Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['city'] ?? 'City not listed',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  if (data['specialties'] != null)
                    Wrap(
                      spacing: 8,
                      children: (data['specialties'] as List)
                          .map<Chip>((spec) => Chip(label: Text(spec)))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 5),
                      Text('Consultation: ${data['price'] ?? 'N/A'} SAR'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("About Lawyer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['bio'] ?? 'No bio available.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text("Start Consultation"),
                        onPressed: () {
                          // Add your chat or booking logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA6847C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.rate_review),
                        label: const Text("Leave Review"),
                        onPressed: () {
                          // Add review logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF062531),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
