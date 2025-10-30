import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;




import 'dart:convert';
import 'package:http/http.dart' as http;


enum Role { user, assistant, typing, documentOptions, pdfFile }



class Message {
  final String text;
  final Role role;
  Message({required this.text, required this.role});
}


const String kWaitingSvg = 'assets/icons/waiting_response.svg';


class LegalChatBot extends StatefulWidget {
  const LegalChatBot({Key? key}) : super(key: key);

  @override
  State<LegalChatBot> createState() => _LegalChatBotState();
}

class _LegalChatBotState extends State<LegalChatBot> {

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();


  final List<Message> _messages = [];
  String? selectedDocumentType;
  List<String> pendingQuestions = [];
  int currentQuestionIndex = 0;
  List<String> userAnswers = [];



  final Map<String, List<String>> documentQuestions = {
    "عقد نفقة": [
      "ما اسم الأب الكامل؟",
      "ما رقم الهوية الوطنية للأب؟",
      "ما اسم الأم الكامل؟",
      "ما رقم الهوية الوطنية للأم؟",
      "كم عدد الأطفال؟",
      "كم مبلغ النفقة لكل طفل؟",
      "كيف سيتم دفع النفقة؟ (الدفع النقدي / التحويل البنكي)",
      "متى يبدأ الالتزام بالدفع؟",
      "هل توجد شروط إضافية؟"
    ],
    "اتفاق حضانة": [
      "ما اسم الطرف الأول؟",
      "ما اسم الطرف الثاني؟",
      "اسم الطفل / الأطفال؟",
      "ما مدة الحضانة؟",
      "اذكر الشروط المحددة للحضانة.",
      "من المسؤول عن النفقات اليومية؟"
    ],
    "إشعار طلاق": [
      "اسم الزوج؟",
      "اسم الزوجة؟",
      "تاريخ الزواج؟",
      "تاريخ الطلاق أو الرغبة في الطلاق؟",
      "سبب الطلاق?",
      "اذكر عدد الأطفال من الزواج (اكتب لا يوجد إذا لم يكن هناك أطفال)."
    ],
    "اتفاق عدم التعرض": [
      "ما اسم الطرف الأول؟",
      "ما اسم الطرف الثاني؟",
      "ما نوع العلاقة بين الطرفين؟ (زمالة، جيرة، شراكة...)",
      "اذكر أي مضايقات أو تهديدات سابقة بين الطرفين.",
      "ما البنود التي يوافق الطرفان على الالتزام بها؟",
      "ما مدة سريان الاتفاق؟",
      "اذكر أسماء الشهود على الاتفاق إن وُجدوا."
    ],
  };



  static const Color kBg = Color(0xFFEFECE8);    
  static const Color kNavy = Color(0xFF062531);   
  static const Color kTyping = Color(0xFF005A4F); 
  static const Color kDots = Color(0xFFD9D9D9);   


  static const String kApiBase = 'https://83dbdf18c356.ngrok-free.app';
  static const String kChatPath = '/ask';


  Future<String> sendMessageToAPI(String message) async {
    try {

      if (message.trim().split(' ').length < 2) {
        return '❌ الرجاء كتابة سؤالك القانوني بشكل أوضح.';
      }

      final uri = Uri.parse('$kApiBase$kChatPath');
      final resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'q': message}),
      )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));


        if (data is Map && (data['answer'] != null || data['reply'] != null)) {
          return (data['answer'] ?? data['reply']).toString();
        }


        if (data is Map && data['best'] is Map && (data['best']['answer'] != null)) {
          return data['best']['answer'].toString();
        }


        if (data is Map && data['results'] is List && data['results'].isNotEmpty) {
          final first = data['results'][0];
          if (first is Map && first['answer'] != null) {
            return first['answer'].toString();
          }
        }

        
        return data.toString();
      } else {
        return '❌ خطأ من الخادم (${resp.statusCode}).';
      }
    } catch (e) {
      return '❌ تعذّر الاتصال بالخادم: $e';
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, role: Role.user));
      _controller.clear();
    });
    _scrollToEnd();


    if (pendingQuestions.isNotEmpty && selectedDocumentType != null) {
      if (!_isValidAnswer(pendingQuestions[currentQuestionIndex], text)) {
        setState(() {
          _messages.add(Message(text: '⚠️ الرجاء إدخال إجابة صحيحة لهذا السؤال.', role: Role.assistant));
        });
        return;
      }

      userAnswers.add(text);
      currentQuestionIndex++;

      if (currentQuestionIndex < pendingQuestions.length) {
       
        setState(() {
          _messages.add(Message(
            text: pendingQuestions[currentQuestionIndex],
            role: Role.assistant,
          ));
        });
        return;
      } else {

        final summary = StringBuffer('📄 تم إدخال البيانات التالية لـ "$selectedDocumentType":\n\n');
        for (int i = 0; i < userAnswers.length; i++) {
          summary.writeln('${i + 1}. ${pendingQuestions[i]}');
          summary.writeln('   → ${userAnswers[i]}');
        }

        final questionsCopy = List<String>.from(pendingQuestions);
        final answersCopy = List<String>.from(userAnswers);

        await generatePDF(selectedDocumentType!, questionsCopy, answersCopy);

        setState(() {
          selectedDocumentType = null;
          pendingQuestions = [];
          currentQuestionIndex = 0;
          userAnswers = [];
        });


        return;
      }
    }


    if (documentQuestions.containsKey(text)) {
      selectedDocumentType = text;
      pendingQuestions = documentQuestions[text]!;
      currentQuestionIndex = 0;
      userAnswers = [];

      setState(() {
        _messages.add(Message(
          text: pendingQuestions.first,
          role: Role.assistant,
        ));
      });
      return;
    }


    setState(() {
      _messages.add(Message(text: '', role: Role.typing));
    });
    _scrollToEnd();

    final reply = await sendMessageToAPI(text);

    setState(() {
      if (_messages.isNotEmpty && _messages.last.role == Role.typing) {
        _messages.removeLast();
      }
      _messages.add(Message(text: reply, role: Role.assistant));
    });
    _scrollToEnd();
  }

  bool _isValidAnswer(String question, String answer) {
    if (answer.trim().isEmpty) return false;

    if (question.contains('هوية')) {
      return RegExp(r'^\d{10}$').hasMatch(answer.trim());
    }

 
    if (question.contains('تاريخ')  || question.contains('كم') || question.contains('مدة')) {
      return RegExp(r'^(\d{1,4}([/\-]\d{1,2}([/\-]\d{2,4})?)?|\d+\s?[أ-يa-zA-Z]+)$').hasMatch(answer);
    }

  
    if (answer.trim().length < 2) return false;

    return true; 
  }


  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String generateContractTemplate(String type, List<String> answers) {
    switch (type) {
      case "عقد نفقة":
        return """

تم الاتفاق بين الطرفين على ما يلي:

الأب ${answers[0]} رقم الهوية: ${answers[1]}  
والأم ${answers[2]} رقم الهوية: ${answers[3]}.

عدد الأطفال: ${answers[4]}.
مقدار النفقة لكل طفل: ${answers[5]} ريال.
يتم دفع النفقة عن طريق ${answers[6]} ابتداءً من تاريخ ${answers[7]}.

الشروط الإضافية (إن وُجدت): ${answers[8]}.

وبهذا تم الاتفاق برضا الطرفين دون إكراه.
""";

      case "اتفاق حضانة":

        String formattedConditions;
        String normalized = answers[4].replaceAll('،', ',');

        if (normalized.contains(',')) {
          formattedConditions = normalized
              .split(',')
              .map((c) => '• ${c.trim()}')
              .join('\n');
        } else {
          formattedConditions = normalized.trim();
        }

        return """
اتفق الطرفان ${answers[0]} و${answers[1]} على أن تكون حضانة الأطفال ${answers[2]} لمدة ${answers[3]}.

الشروط المحددة للحضانة:
$formattedConditions

يتحمل ${answers[5]} النفقات اليومية للأبناء.
تم هذا الاتفاق برضا الطرفين.
""";


      case "إشعار طلاق":
        return """

يُقر السيد ${answers[0]} والسيدة ${answers[1]} برغبتهما في إنهاء عقد الزواج الذي تم بتاريخ ${answers[2]}.

وقد تم الطلاق بتاريخ ${answers[3]}.
سبب الطلاق: ${answers[4]}.
عدد الأطفال من الزواج: ${answers[5]}.

وبناءً عليه، تم اعتماد هذا الإشعار بموجب رضا الطرفين دون أي اعتراض.
""";

      case "اتفاق عدم التعرض":
        return """
تم الاتفاق بين ${answers[0]} و${answers[1]} على الحفاظ على علاقة ${answers[2]}، وعدم التعرض أو المضايقة بأي شكل.

يقر الطرفين بأنه ${answers[3]}.
البنود المتفق عليها: ${answers[4]}.
مدة الاتفاق: ${answers[5]}.
وجود شهود: ${answers[6]}.

وبناءً على ما تقدم، تم تحرير هذا الاتفاق برضا الطرفين دون أي إكراه.
""";

      default:
        return "نص العقد غير محدد لهذا النوع.";
    }
  }


  Future<void> generatePDF(String title, List<String> questions, List<String> answers) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";


    final contractText = generateContractTemplate(title, answers);


    final fontData = await rootBundle.load('assets/Front/Cairo/static/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 8),
                pw.Text(title, style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 13),

                pw.Container(
                  width: double.infinity,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('التاريخ: $formattedDate', style: pw.TextStyle(font: ttf, fontSize: 16)),
                  ),
                ),
                pw.SizedBox(height: 22),
                pw.Text(
                  contractText,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: ttf, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/${title.replaceAll(" ", "_")}.pdf');
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _messages.add(
        Message(
          text: 'تم إنشاء المستند "$title" بنجاح.\n\nاضغط لفتح الملف:',
          role: Role.assistant,
        ),
      );

      _messages.add(
        Message(
          text: file.path,
          role: Role.pdfFile,
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 4,
        title: const Text(
          'المساعد القانوني',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {

                  return _buildBubble(_messages[i]);
                },
              ),
            ),
          ),


         
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  InkWell(
                    onTap: () {

                      setState(() {
                        _messages.add(Message(
                          text: "ما نوع المستند الذي ترغب في إنشائه؟",
                          role: Role.assistant,
                        ));
                        _messages.add(Message(
                          text: "doc_type_selection",
                          role: Role.documentOptions,
                        ));
                      });
                      _scrollToEnd();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(

                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 48,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "إنشاء عقد",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),


                  Container(
                    height: 30,
                    width: 2,
                    color: Colors.white.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),


                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: '... اكتب سؤالك القانوني',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _send(),
                    ),
                  ),

                  const SizedBox(width: 8),


                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: kBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/bot-svgrepo-com.svg',
                          width: 30,
                          height: 30,
                          color: kTyping,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBubble(Message m) {
    switch (m.role) {
      case Role.user:
        return NormalChatBubble(
          text: m.text,
          alignRight: true,
          bgColor: Color(0xFF9B7D73),
          textColor: Colors.white,
        );
      case Role.assistant:
        return NormalChatBubble(
          text: m.text,
          alignRight: false,
          bgColor: kNavy,
          textColor: Colors.white,
        );
      case Role.typing:
        if (m.text == "doc_type_selection") {
          return const DocumentTypeOptions();
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: WaitingBubbleSvg(),
          );
        }
      case Role.documentOptions:
        return const DocumentTypeOptions();

      case Role.pdfFile:
        return GestureDetector(
          onTap: () {
            OpenFile.open(m.text);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Text("فتح الملف", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        );
    }
  }




  void _handleContractStart() {
    setState(() {
      _messages.add(Message(
        text: 'ما نوع المستند الذي ترغب في إنشائه؟\n\n'
            '📄 عقد نفقة\n'
            '👶 اتفاق حضانة\n'
            ' إشعار طلاق\n'
            ' اتفاق عدم التعرضر',
        role: Role.assistant,
      ));
    });
    _scrollToEnd();
  }

}


class NormalChatBubble extends StatelessWidget {
  final String text;
  final bool alignRight;
  final Color bgColor;
  final Color textColor;

  const NormalChatBubble({
    super.key,
    required this.text,
    required this.alignRight,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: alignRight ? Radius.circular(18) : Radius.circular(0),
            bottomRight: alignRight ? Radius.circular(0) : Radius.circular(18),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}


class WaitingBubbleSvg extends StatelessWidget {
  const WaitingBubbleSvg({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 45,
        height: 25,
        child: SvgPicture.asset(
          kWaitingSvg,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class DocumentTypeOptions extends StatelessWidget {
  const DocumentTypeOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> options = [
      'عقد نفقة',
      'اتفاق حضانة',
      'إشعار طلاق',
      'اتفاق عدم التعرض',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9B7D73),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {

              final parentState = context.findAncestorStateOfType<_LegalChatBotState>();
              if (parentState != null) {
                parentState._controller.text = option;
                parentState._send();
              }
            },
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}
