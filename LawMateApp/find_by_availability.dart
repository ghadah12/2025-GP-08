import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lawyer_profile.dart';

class FindByAvailabilityPage extends StatelessWidget {
  const FindByAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text('Available Lawyers'),
        backgroundColor: const Color(0xFF062531),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 10),
            child: const Text(
              "This page shows only lawyers who are currently available for consultation based on your request.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "List of Lawyers",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('LegalProfessional')
                  .where('is_approved', isEqualTo: true)
                  .where('is_available', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No available lawyers found.'));
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _lawyerCard(context, data, doc.id);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _lawyerCard(BuildContext context, Map<String, dynamic> data, String docId) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: data['photo_url'] != null && data['photo_url'] != ''
                ? NetworkImage(data['photo_url'])
                : const AssetImage('assets/images/hk.jpeg') as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(data['display_name'] ?? 'Name', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text((data['specialties'] as List?)?.join(', ') ?? 'Specialty'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LawyerProfilePage(lawyerId: docId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF062531),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Request Consultation", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF062531),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "My Consultations"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
