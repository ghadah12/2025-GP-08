import 'package:flutter/material.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE8),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: <Widget>[
              // ✅ المستطيل اللحمي العلوي
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

              // ✅ الصورة الدائرية (Avatar)
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

              // ✅ الاسم
              const Positioned(
                top: 320,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'اسم الفرد',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Inter',
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // ✅ مربع تصنيف الاستشارة
              Positioned(
                top: 380,
                left: 20,
                right: 20,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF062531),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    ': تصنيف الإستشارة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // ✅ مربع الوصف
              Positioned(
                top: 450,
                left: 20,
                right: 20,
                child: Container(
                  height: 118,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF062531),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      ': الوصف',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
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
      ),
    );
  }
}
