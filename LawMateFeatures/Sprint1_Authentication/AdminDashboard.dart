import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  
  bool isLoggedIn = false;
  String adminName = "";
  bool _isLoading = false;
  bool _obscurePassword = true;

  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  Future<void> _checkAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Admins')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          isLoggedIn = true;
          adminName = data['name'] ?? 'Admin';
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("أهلاً بك يا $adminName")));
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البيانات غير صحيحة')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  
  Future<void> approveLawyer(String lawyerId, String lawyerName) async {
    try {
      await FirebaseFirestore.instance.collection('LegalProfessional').doc(lawyerId).update({
        'is_approved': true,
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': lawyerId,
        'title': "تم توثيق حسابك!🎉",
        'body': "تهانينا! تمت الموافقة على حسابك كمحامي.",
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  
  Future<void> rejectLawyer(String lawyerId, String lawyerName) async {
    try {
      
      await FirebaseFirestore.instance.collection('LegalProfessional').doc(lawyerId).delete();

    } catch (e) {
      debugPrint("Error rejecting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn) {
      return _buildDashboardView();
    } else {
      return _buildLoginView(context);
    }
  }

  
  Widget _buildLoginView(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Beige_and_Brown_Aesthetic_Background_Instagram_Story2.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 50, left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('بوابة المشرفين', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown[800], fontFamily: 'Inter')),
                      const SizedBox(height: 50),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                        ),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _checkAdminLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA6847C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildDashboardView() {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة تحكم: $adminName", style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF062531),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => setState(() { isLoggedIn = false; adminName = ""; _emailController.clear(); _passwordController.clear(); }),
          )
        ],
      ),
      backgroundColor: const Color(0xFFEFECE8),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('LegalProfessional').where('is_approved', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 15),
                  const Text("لا يوجد محامين بانتظار التفعيل", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final lawyers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lawyers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = lawyers[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['display_name'] ?? 'محامٍ';
              final email = data['email'] ?? '';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          
                          builder: (context) => LawyerDetailsAdminView(lawyerData: data),
                        ),
                      );
                    },
                    

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF062531),
                      child: const Icon(Icons.gavel, color: Colors.white),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: FittedBox(
                      fit: BoxFit.scaleDown, 
                      alignment: Alignment.centerLeft, 
                      child: Text( email, style: const TextStyle(fontSize: 14, color: Colors.black54,),),),

                    
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(60, 36), 
                          ),
                          onPressed: () {
                            approveLawyer(doc.id, name);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم القبول بنجاح")));
                          },
                          child: const Text("قبول", style: TextStyle(fontSize: 12)), 
                        ),

                        const SizedBox(width: 8), 

                        
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(60, 36),
                          ),
                          onPressed: () {
                            rejectLawyer(doc.id, name);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم رفض الطلب")));
                          },
                          child: const Text("رفض", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class LawyerDetailsAdminView extends StatelessWidget {
  final Map<String, dynamic> lawyerData;

  const LawyerDetailsAdminView({super.key, required this.lawyerData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062531),
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('تفاصيل المحامي', style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             
              Container(
                width: 107, height: 107,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 4)],
                ),
                child: Center(
                  child: SvgPicture.asset('assets/icons/lawyer-svgrepo-com.svg', width: 60, height: 60),
                ),
              ),
              const SizedBox(height: 10),

             
              Text(
                lawyerData['display_name'] ?? 'اسم المحامي',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

             
              Container(
                width: 250, height: 2,
                color: const Color(0xFF917268),
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),

              
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  children: [
                    _infoRow('assets/icons/building.svg', 'المدينة: ${lawyerData['city'] ?? 'غير محدد'}'),
                    const SizedBox(height: 30),
                    _infoRow('assets/icons/license-svgrepo-com (2).svg', 'رقم الرخصة: ${lawyerData['lawlicense'] ?? 'غير موجود'}'),
                    const SizedBox(height: 30),
                    _infoRow('assets/icons/balance.svg', 'التخصص: ${lawyerData['specialties']?.join("، ") ?? 'غير محدد'}'),
                    const SizedBox(height: 30),
                    _infoRow('assets/icons/Saudi_Riyal_Symbol-2.svg', 'السعر: ${lawyerData['price'] ?? 'غير محدد'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
  Widget _infoRow(String iconPath, String label) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF062531), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(iconPath, color: Colors.white, width: 24, height: 24),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 18), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
