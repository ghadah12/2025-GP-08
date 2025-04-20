import 'package:flutter/material.dart';
import 'find_by_availability.dart';
import 'find_by_name.dart';

class FindLawyerHomePage extends StatelessWidget {
  const FindLawyerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: const Text('Find a Lawyer'),
        backgroundColor: const Color(0xFF062531),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Please Select your Search option',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindByNamePage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA6847C),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("By Name"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FindByAvailabilityPage()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA6847C),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("By Availability"),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "List of Lawyers",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(5, (index) {
                return _lawyerCard(context);
              }),
            ),
          )
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _lawyerCard(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
          const SizedBox(height: 10),
          const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("Specialty"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Will navigate to LawyerProfile
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
