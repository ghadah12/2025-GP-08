import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomePage.dart';

class UserSignIn extends StatefulWidget {
  const UserSignIn({super.key});

  @override
  State<UserSignIn> createState() => _UserSignInState();
}

class _UserSignInState extends State<UserSignIn> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;
  final _formLoginKey = GlobalKey<FormState>();
  final _formSignUpKey = GlobalKey<FormState>();

  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  final _emailSignUpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordSignUpController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _emailSignUpController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _passwordSignUpController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailLoginController.text.trim(),
        password: _passwordLoginController.text.trim(),
      );

      final uid = credential.user!.uid;

      final doc = await FirebaseFirestore.instance.collection('Individual').doc(uid).get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              ' لا يوجد بيانات لهذا المستخدم في قاعدة البيانات',
              textAlign: TextAlign.center,
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            ' تم تسجيل الدخول',
            textAlign: TextAlign.center,
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            ' البريد الإلكتروني أو كلمة المرور غير صحيحة',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/userlawyer.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.brown[800],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.brown[300],
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'تسجيل الدخول'),
                    Tab(text: 'إنشاء حساب'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [

                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formLoginKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _emailLoginController,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                value!.isEmpty ? 'أدخل البريد الإلكتروني' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordLoginController,
                                obscureText: _obscureLoginPassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureLoginPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureLoginPassword = !_obscureLoginPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) =>
                                value!.isEmpty ? 'أدخل كلمة المرور' : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formLoginKey.currentState!.validate()) {
                                    await loginUser();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA6847C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                ),
                                child: const Text('تسجيل الدخول'),
                              ),
                            ],
                          ),
                        ),
                      ),


                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formSignUpKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _emailSignUpController,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                value!.isEmpty ? 'أدخل البريد الإلكتروني' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'اسم المستخدم',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                value!.isEmpty ? 'أدخل اسم المستخدم' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneNumberController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الجوال',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'أدخل رقم الجوال';
                                  } else if (!RegExp(r'^[0-9]{9,15}$').hasMatch(value)) {
                                    return 'رقم الجوال غير صالح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordSignUpController,
                                obscureText: _obscureSignUpPassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSignUpPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureSignUpPassword = !_obscureSignUpPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'أدخل كلمة المرور';
                                  } else if (value.length < 8) {
                                    return 'كلمة المرور يجب أن تكون على الأقل 8 أحرف';
                                  } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                    return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
                                  } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                                    return 'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';
                                  } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                                    return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
                                  } else if (!RegExp(r'[!@#\$&*~%^()_+=\-]').hasMatch(value)) {
                                    return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'تأكيد كلمة المرور',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value != _passwordSignUpController.text) {
                                    return 'كلمة المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formSignUpKey.currentState!.validate()) {
                                    try {
                                      UserCredential userCredential =
                                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                        email: _emailSignUpController.text.trim(),
                                        password: _passwordSignUpController.text.trim(),
                                      );

                                      await userCredential.user!.updateDisplayName(_usernameController.text.trim());

                                      String uid = userCredential.user!.uid;

                                      await FirebaseFirestore.instance.collection('Individual').doc(uid).set({
                                        'uid': uid,
                                        'email': _emailSignUpController.text.trim(),
                                        'display_name': _usernameController.text.trim(),
                                        'phone_number': _phoneNumberController.text.trim(),
                                        'photo_url': '',
                                        'created_time': FieldValue.serverTimestamp(),
                                        'userType': 'individual',
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            ' تم إنشاء الحساب بنجاح!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HomePage()),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage = ' حدث خطأ أثناء إنشاء الحساب';

                                      if (e.code == 'invalid-email') {
                                        errorMessage = ' صيغة البريد الإلكتروني غير صحيحة';
                                      } else if (e.code == 'email-already-in-use') {
                                        errorMessage = ' هذا البريد الإلكتروني مستخدم مسبقًا';
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(errorMessage, textAlign: TextAlign.center)),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA6847C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('إنشاء الحساب'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
