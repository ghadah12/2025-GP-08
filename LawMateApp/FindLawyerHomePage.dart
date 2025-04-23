import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lawyer_profile.dart';

class FindLawyerHomePage extends StatefulWidget {
  const FindLawyerHomePage({super.key});

  @override
  State<FindLawyerHomePage> createState() => _FindLawyerHomePageState();
}

class _FindLawyerHomePageState extends State<FindLawyerHomePage> {
  String selectedFilter = 'name';
  String searchName = '';
  final TextEditingController _searchController = TextEditingController();
  String? selectedLawyerId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF062531),
          leading: IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () async {
              if (selectedLawyerId != null) {
                final doc = await FirebaseFirestore.instance.collection('LegalProfessional').doc(selectedLawyerId).get();

                if (doc.exists) {
                  final data = doc.data()!;
                  final name = data['display_name'] ?? '';
                  final price = data['price']?.toString() ?? '';

                  Navigator.pop(context, {
                    'name': name,
                    'price': price,
                    'id': doc.id,
                  });
                } else {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },


          ),
        ),
        backgroundColor: const Color(0xFFF5EFE6),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF062531),
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedFilter,
                dropdownColor: const Color(0xFF062531),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('حسب الاسم'),
                  ),
                  DropdownMenuItem(
                    value: 'availability',
                    child: Text('حسب التوفر'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedFilter = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "قائمة المحامين:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchName = value.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المحامي...',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('LegalProfessional')
                      .where('is_approved', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("لا يوجد محامين معتمدين حالياً"));
                    }

                    final lawyers = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final name = (data['display_name'] ?? '').toString().trim().toLowerCase();
                      final state = data['state']?.toString().toLowerCase();

                      final nameMatch = name.isNotEmpty &&
                          (searchName.isEmpty || name.contains(searchName.toLowerCase()));

                      if (selectedFilter == 'availability') {
                        return nameMatch && state == 'available';
                      } else {
                        return nameMatch;
                      }
                    }).toList();

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: lawyers.length,
                      itemBuilder: (context, index) {
                        final lawyerDoc = lawyers[index];
                        final lawyer = lawyerDoc.data() as Map<String, dynamic>;
                        final lawyerId = lawyerDoc.id;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF062531),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Center(
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (lawyer['photo_url'] != null &&
                                          lawyer['photo_url'].toString().isNotEmpty)
                                          ? NetworkImage(lawyer['photo_url'])
                                          : null,
                                      child: (lawyer['photo_url'] == null ||
                                          lawyer['photo_url'].toString().isEmpty)
                                          ? const Icon(Icons.person, size: 30, color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: Checkbox(
                                      value: selectedLawyerId == lawyerId,
                                      onChanged: (_) {
                                        setState(() {
                                          if (selectedLawyerId == lawyerId) {
                                            selectedLawyerId = null;
                                          } else {
                                            selectedLawyerId = lawyerId;
                                          }
                                        });
                                      },
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      side: const BorderSide(color: Colors.white),
                                      checkColor: Colors.white,
                                      activeColor: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                lawyer['display_name'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${lawyer['price'] ?? '---'} ريال',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child:ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LawyerProfile(lawyerId: lawyerId),
                                      ),
                                    );
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('الملف الشخصي', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
