import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lawyer_profile.dart';


class FindLawyerHomePage extends StatefulWidget {

  final String selectedType;

  const FindLawyerHomePage({Key? key, required this.selectedType}) : super(key: key);

  @override
  State<FindLawyerHomePage> createState() => _FindLawyerHomePageState();
}

class _FindLawyerHomePageState extends State<FindLawyerHomePage> {
  String selectedFilter = 'name';
  String searchName = '';
  final TextEditingController _searchController = TextEditingController();
  String? selectedLawyerId;


  String availabilityFilter = 'all';
  String priceSortOrder = 'none';


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5EFE6),
          leading: IconButton(
            icon: const Icon(Icons.check, color: Colors.black , size: 30),
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
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "قائمة المحامين:",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
            ),


            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showFilterSheet(context),
                    icon: const Icon(Icons.filter_list),
                    label: const Text('فلترة المحامين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF062531),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
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
                      .where('specialties', arrayContains: widget.selectedType)
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
                      final nameMatch = name.isNotEmpty && (searchName.isEmpty || name.contains(searchName.toLowerCase()));
                      final availabilityMatch = availabilityFilter == 'all' || state == 'available';
                      return nameMatch && availabilityMatch;
                    }).toList();

                    if (priceSortOrder == 'asc') {
                      lawyers.sort((a, b) {
                        final priceA = (a.data() as Map<String, dynamic>)['price'] ?? 0;
                        final priceB = (b.data() as Map<String, dynamic>)['price'] ?? 0;
                        return priceA.compareTo(priceB);
                      });
                    } else if (priceSortOrder == 'desc') {
                      lawyers.sort((a, b) {
                        final priceA = (a.data() as Map<String, dynamic>)['price'] ?? 0;
                        final priceB = (b.data() as Map<String, dynamic>)['price'] ?? 0;
                        return priceB.compareTo(priceA);
                      });
                    }

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
                        final state = lawyer['state']?.toString().toLowerCase() ?? '';
                        final isAvailable = state == 'available';
                        final lawyerId = lawyerDoc.id;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAvailable ? const Color(0xFF062531) : const Color(0xFF204556),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        onChanged: isAvailable
                                            ? (_) {
                                          setState(() {
                                            if (selectedLawyerId == lawyerId) {
                                              selectedLawyerId = null;
                                            } else {
                                              selectedLawyerId = lawyerId;
                                            }
                                          });
                                        }
                                            : null,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4)),
                                        side: BorderSide(
                                            color: isAvailable ? Colors.white : Colors.grey[300]!),
                                        checkColor: Colors.white,
                                        activeColor: isAvailable ? Colors.teal : Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  lawyer['display_name'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                if (!isAvailable) const SizedBox(height: 4),
                                if (!isAvailable)
                                  const Text(
                                    'غير متاح حالياً',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  '${lawyer['price'] ?? '---'} ريال',
                                  style: const TextStyle(color: Colors.white),
                                ),FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Ratings')
                                      .where('lawyer_id', isEqualTo: lawyerId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox(height: 20);
                                    }

                                    final docs = snapshot.data!.docs;
                                    if (docs.isEmpty) {
                                      return const Text(
                                        "لا يوجد تقييمات بعد",
                                        style: TextStyle(fontSize: 12, color: Colors.white70),
                                      );
                                    }

                                    final average = docs
                                        .map((d) => d['rating'] as num)
                                        .reduce((a, b) => a + b) / docs.length;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text(
                                          average.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                        Text(
                                          ' (${docs.length})',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),


                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
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
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('الملف الشخصي',
                                        style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 8),




                              ],

                            ),
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('فلترة المحامين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('حسب التوفر:', style: TextStyle(fontSize: 16)),
                    RadioListTile(
                      title: const Text('الكل'),
                      value: 'all',
                      groupValue: availabilityFilter,
                      onChanged: (value) => setModalState(() => availabilityFilter = value as String),
                    ),
                    RadioListTile(
                      title: const Text('عرض المتاح فقط'),
                      value: 'available',
                      groupValue: availabilityFilter,
                      onChanged: (value) => setModalState(() => availabilityFilter = value as String),
                    ),

                    const SizedBox(height: 16),
                    const Text(' ترتيب السعر:'),
                    RadioListTile(
                      title: const Text('من الأقل للأعلى سعرًا'),
                      value: 'asc',
                      groupValue: priceSortOrder,
                      onChanged: (value) => setModalState(() => priceSortOrder = value as String),
                    ),
                    RadioListTile(
                      title: const Text('من الأعلى للأقل سعرًا'),
                      value: 'desc',
                      groupValue: priceSortOrder,
                      onChanged: (value) => setModalState(() => priceSortOrder = value as String),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        label: const Text('تطبيق الفلاتر'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
