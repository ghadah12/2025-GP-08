import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:string_similarity/string_similarity.dart';


class LegalGuidePage extends StatefulWidget {
  const LegalGuidePage({super.key});

  static String routeName = '/legalGuide';

  @override
  State<LegalGuidePage> createState() => _LegalGuidePageState();
}

class _LegalGuidePageState extends State<LegalGuidePage> {
  final TextEditingController _controller = TextEditingController();

  final Map<String, String> keywordsMap = {

    'طلاق': 'الأحوال الشخصية',
    'انفصال': 'الأحوال الشخصية',
    'فسخ زواج': 'الأحوال الشخصية',
    'خلع': 'الأحوال الشخصية',
    'نفقة': 'الأحوال الشخصية',
    'مصروف': 'الأحوال الشخصية',
    'حضانة': 'الأحوال الشخصية',
    'رعاية طفل': 'الأحوال الشخصية',
    'زواج': 'الأحوال الشخصية',
    'عقد نكاح': 'الأحوال الشخصية',
    'وصاية': 'الأحوال الشخصية',
    'ولاية': 'الأحوال الشخصية',


    'إيجار': 'العقود والإيجارات',
    'عقد': 'العقود والإيجارات',
    'مستأجر': 'العقود والإيجارات',
    'مؤجر': 'العقود والإيجارات',
    'سكن': 'العقود والإيجارات',
    'شقة': 'العقود والإيجارات',


    'محكمة': 'المحاكم والقضايا',
    'جلسة': 'المحاكم والقضايا',
    'دعوى': 'المحاكم والقضايا',
    'قضية': 'المحاكم والقضايا',
    'مرافعة': 'المحاكم والقضايا',
    'استئناف': 'المحاكم والقضايا',


    'مخالفة': 'المخالفات المرورية',
    'غرامة': 'المخالفات المرورية',
    'مرور': 'المخالفات المرورية',
    'رخصة': 'المخالفات المرورية',
    'حوادث': 'المخالفات المرورية',
    'تجديد استمارة': 'المخالفات المرورية',


    'شركة': 'الخدمات التجارية',
    'سجل تجاري': 'الخدمات التجارية',
    'علامة': 'الخدمات التجارية',
    'براند': 'الخدمات التجارية',
    'تجارة': 'الخدمات التجارية',
    'استثمار': 'الخدمات التجارية',
    'مؤسسة': 'الخدمات التجارية',


    'حقوق': 'الخدمات العامة',
    'مظلمة': 'الخدمات العامة',
    'تظلم': 'الخدمات العامة',
    'معاملة': 'الخدمات العامة',
    'بلاغ': 'الخدمات العامة',
    'شكاوي': 'الخدمات العامة',
  };

  final Map<String, List<Map<String, String>>> resources = {
    "الأحوال الشخصية": [
      {"name": "منصة ناجز", "url": "https://najiz.sa"},
      {"name": "منصة تراضي", "url": "https://taradhi.moj.gov.sa"},
    ],
    "العقود والإيجارات": [
      {"name": "منصة إيجار", "url": "https://ejar.sa/ar"},
    ],
    "المحاكم والقضايا": [
      {"name": "ناجز - رفع الدعاوى", "url": "https://najiz.sa/applications"},
      {"name": "دليل المحاكم", "url": "https://www.moj.gov.sa"},
    ],
    "المخالفات المرورية": [
      {"name": "منصة أبشر", "url": "https://www.absher.sa"},
    ],
    "الخدمات التجارية": [
      {"name": "وزارة التجارة", "url": "https://mc.gov.sa"},
      {"name": "الملكية الفكرية", "url": "https://saip.gov.sa"},
    ],
    "الخدمات العامة": [
      {"name": "ديوان المظالم", "url": "https://www.bog.gov.sa"},
      {"name": "هيئة حقوق الإنسان", "url": "https://www.hrc.gov.sa"},
    ],
  };


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      debugPrint("🔗 محاولة فتح الرابط: $url");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint("✅ تم فتح الرابط بنجاح");
      } else {
        debugPrint("❌ ماقدر يفتح الرابط: $url");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ما قدرت أفتح الرابط: $url")),
        );
      }
    } catch (e) {
      debugPrint("⚠️ خطأ أثناء محاولة فتح الرابط: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("صار خطأ: $e")),
      );
    }
  }


  void _searchKeyword() {
    String input = _controller.text.trim();
    String? foundCategory;
    List<String> suggestions = [];


    keywordsMap.forEach((key, value) {
      if (input.contains(key) || key.contains(input)) {
        foundCategory = value;
      } else if (key.startsWith(input)) {
        suggestions.add(key);
      }
    });

    if (foundCategory != null) {

      _showCategoryDialog(foundCategory!);
    } else if (suggestions.isNotEmpty) {

      _showSuggestionsDialog(suggestions);
    } else {

      _showCategorySuggestionsDialog(resources.keys.toList());
    }
  }


  void _showSuggestionsDialog(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("هل تقصد؟"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((s) {
              return ListTile(
                title: Text(s),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryDialog(keywordsMap[s]!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق"),
            ),
          ],
        );
      },
    );
  }


  void _showCategorySuggestionsDialog(List<String> categories) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("اختر القسم المناسب"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((c) {
              return ListTile(
                title: Text(c),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryDialog(c);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق"),
            ),
          ],
        );
      },
    );
  }



  void _showCategoryDialog(String category) {
    final links = resources[category] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF4E3DB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            category,
            style: const TextStyle(
              color: Color(0xFF052532),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: links.map((link) {
              return ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF9B7D73)),
                title: Text(link["name"]!),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(link["url"]!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق", style: TextStyle(color: Color(0xFF052532))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(String title, IconData icon) {
    return Card(
      color: const Color(0xFF9B7D73),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCategoryDialog(title),
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E3DB),

      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),

        title: const Text(
          "الدليل القانوني",
          style: TextStyle(color:Colors.white),
        ),

        backgroundColor: const Color(0xFF052532),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextField(
              controller: _controller,
              onSubmitted: (_) => _searchKeyword(),
              decoration: InputDecoration(
                hintText: "اكتب مشكلتك (مثال: عندي جلسة محكمة)...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF052532)),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),


            const SizedBox(height: 20),

            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard("الأحوال الشخصية", Icons.family_restroom),
                  _buildCard("العقود والإيجارات", Icons.home),
                  _buildCard("المحاكم والقضايا", Icons.balance),
                  _buildCard("المخالفات المرورية", Icons.directions_car),
                  _buildCard("الخدمات التجارية", Icons.business_center),
                  _buildCard("الخدمات العامة", Icons.gavel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
