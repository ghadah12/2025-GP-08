import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'SignUpUserLawyer.dart';
import 'HomePage.dart';
import 'logOut.dart';
import 'ConsultationStatusPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeWidget(),

      routes: {
        '/signUpUserLawyer': (context) => const SignUpUserLawyer(),
        HomePage.routeName: (context) => const HomePage(),
        LogOutPage.routeName: (context) => const LogOutPage(),
      },
    );
  }
}

class WelcomeWidget extends StatefulWidget {
  const WelcomeWidget({super.key});

  static String routeName = 'Welcome';
  static String routePath = '/welcome';

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Blue_White_Minimalist_Hiring_Poster_(1).png',
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpUserLawyer(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B7D73),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                    elevation: 3.0,
                  ),
                  child: const Text(
                    'أبدا رحلتك القانونية',
                    style: TextStyle(
                      fontFamily: 'Inter Tight',
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
