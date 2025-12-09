import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class LawyerSchedulePage extends StatefulWidget {
  const LawyerSchedulePage({Key? key}) : super(key: key);

  @override
  State<LawyerSchedulePage> createState() => _LawyerSchedulePageState();
}

class _LawyerSchedulePageState extends State<LawyerSchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _selectedSlots = {};
  TimeOfDay? _selectedTime;
  Set<String> _bookedSlots = {};
  Set<String> _slotsToMakeAvailable = {};
  Set<DateTime> _holidayDates = <DateTime>{};
  Set<DateTime> _workDays = <DateTime>{};


  bool _hasAnyCards = false;


  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  bool _isHolidayDay(DateTime? d) => d != null && _holidayDates.contains(_d(d));
  bool _isWorkDay(DateTime? d) => d != null && _workDays.contains(_d(d));

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDay!;
    _loadWorkDays();
    _loadHolidays();
  }

  Future<void> _loadWorkDays() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('lawyerId', isEqualTo: currentUser.uid)
        .get();

    final work = <DateTime>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] != null) {
        final dateOnly = DateTime.parse(data['date']);
        work.add(_d(dateOnly));
      }
    }

    setState(() {
      _workDays = work;
    });
  }

  Future<void> _loadHolidays() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('lawyerId', isEqualTo: currentUser.uid)
        .where('isHoliday', isEqualTo: true)
        .get();

    final holidays = <DateTime>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] != null) {
        final dateOnly = DateTime.parse(data['date']);
        holidays.add(_d(dateOnly));
      }
    }

    setState(() {
      _holidayDates = holidays;
    });
  }

  final List<TimeOfDay> _timeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
  ];

  bool _isPastDate(DateTime day) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final selectedOnly = DateTime(day.year, day.month, day.day);
    return selectedOnly.isBefore(todayOnly);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> _loadBookedSlots() async {
    if (_selectedDay == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final dateStr = _selectedDay!.toIso8601String().split('T')[0];
    final snapshot = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('lawyerId', isEqualTo: currentUser.uid)
        .where('date', isEqualTo: dateStr)
        .get();

    final booked = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if ((data['userId'] != null && data['userId'].toString().isNotEmpty) ||
          (data['isAvailable'] == false) ||
          (data['isHoliday'] == true)) {
        booked.add(data['time'] ?? '');
      }
    }

    setState(() {
      _bookedSlots = booked;
      _selectedSlots.clear();
      _slotsToMakeAvailable.clear();
    });
  }

  Future<void> _saveSelectedSlots() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار يوم وأوقات أولاً')),
      );
      return;
    }

    final dateStr = _selectedDay!.toIso8601String().split('T')[0];

    for (final slot in _selectedSlots) {
      final existing = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('lawyerId', isEqualTo: currentUser.uid)
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: slot)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) continue;

      await FirebaseFirestore.instance.collection('Appointments').add({
        'lawyerId': currentUser.uid,
        'userId': null,
        'date': dateStr,
        'time': slot,
        'isAvailable': false,
        'isHoliday': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    for (final slot in _slotsToMakeAvailable) {
      final query = await FirebaseFirestore.instance
          .collection('Appointments')
          .where('lawyerId', isEqualTo: currentUser.uid)
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: slot)
          .limit(1)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الأوقات بنجاح'),
          duration: Duration(seconds: 2),
        ),
      );

    final dateKey = _d(_selectedDay!);
    final dayDocs = await FirebaseFirestore.instance
        .collection('Appointments')
        .where('lawyerId', isEqualTo: currentUser.uid)
        .where('date', isEqualTo: dateStr)
        .get();

    setState(() {
      if (dayDocs.docs.isNotEmpty) {
        _workDays.add(dateKey);
      } else {
        _workDays.remove(dateKey);
      }
    });

    _slotsToMakeAvailable.clear();
    await _loadWorkDays();
    await _loadBookedSlots();
  }

  void _showSlotPicker() async {
    await _loadBookedSlots();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(' اختر أوقات العمل:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) {
                final label = _formatTime(time);
                final isDisabled = _bookedSlots.contains(label);
                final isSelected = _selectedSlots.contains(label);
                final isToRelease = _slotsToMakeAvailable.contains(label);

                return FilterChip(
                  label: Text(label),
                  selected: isDisabled ? isToRelease : isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (isDisabled) {
                        if (val) {
                          _slotsToMakeAvailable.add(label);
                        } else {
                          _slotsToMakeAvailable.remove(label);
                        }
                      } else {
                        if (val) {
                          _selectedSlots.add(label);
                        } else {
                          _selectedSlots.remove(label);
                        }
                      }
                    });
                  },
                  selectedColor: isDisabled ? Colors.red : const Color(0xFF594840),
                  checkmarkColor: Colors.white,
                  labelStyle: const TextStyle(color: Colors.white),
                  backgroundColor: isDisabled ? Colors.grey : const Color(0xFF9B7D73),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveSelectedSlots();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B7D73),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: const Text('حفظ الأوقات'),
            ),
          ],
        ),
      ),
    );
  }


  String _fmtDate(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E3DB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF052532),
        leading: BackButton(
          color: Colors.white,
        ),
        title: const Text('إدارة المواعيد', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            holidayPredicate: (day) => _isHolidayDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              if (_isPastDate(selectedDay)) return;
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadBookedSlots();
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: Color(0xFF052532), shape: BoxShape.circle),
              todayDecoration: const BoxDecoration(color: Color(0xFF052532), shape: BoxShape.circle),
              disabledTextStyle: const TextStyle(color: Colors.grey),
              holidayTextStyle: const TextStyle(color: Colors.grey),
              holidayDecoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
            ),
            enabledDayPredicate: (day) => !_isPastDate(day),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: Color(0xFF052532), fontWeight: FontWeight.bold),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dayOnly = _d(day);
                final isWork = _workDays.contains(dayOnly);
                final isHoliday = _holidayDates.contains(dayOnly);
                final isSelected = isSameDay(_selectedDay, day);
                final isToday = isSameDay(day, DateTime.now());

                if (isWork && !isSelected && !isToday && !isHoliday) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Color(0xFF9B7D73), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_isHolidayDay(_selectedDay)) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                  content: Text('لا يمكن إضافة أوقات في يوم إجازة'),
                                  duration: Duration(seconds: 2),
                                ));
                              return;
                            }
                            _showSlotPicker();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B7D73),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          ),
                          child: const Text(
                            'اختيار الوقت',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (_selectedDay == null || currentUser == null) return;

                            if (!_isHolidayDay(_selectedDay) && _isWorkDay(_selectedDay)) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                  content: Text('لا يمكن تحديد اليوم كإجازة لأنه يحتوي على أوقات عمل'),
                                  duration: Duration(seconds: 2),
                                ));
                              return;
                            }

                            final dateStr = _selectedDay!.toIso8601String().split('T')[0];

                            final snapshot = await FirebaseFirestore.instance
                                .collection('Appointments')
                                .where('lawyerId', isEqualTo: currentUser.uid)
                                .where('date', isEqualTo: dateStr)
                                .limit(1)
                                .get();

                            if (snapshot.docs.isNotEmpty &&
                                snapshot.docs.first['userId'] != null &&
                                snapshot.docs.first['userId'] != "") {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                  content: Text('لا يمكن تحديد/إلغاء اليوم كإجازة لأنه محجوز من قبل مستخدم'),
                                  duration: Duration(seconds: 2),
                                ));
                              return;
                            }

                            if (_isHolidayDay(_selectedDay)) {
                              final query = await FirebaseFirestore.instance
                                  .collection('Appointments')
                                  .where('lawyerId', isEqualTo: currentUser.uid)
                                  .where('date', isEqualTo: dateStr)
                                  .where('isHoliday', isEqualTo: true)
                                  .get();

                              for (var doc in query.docs) {
                                await doc.reference.delete();
                              }

                              setState(() {
                                _holidayDates.remove(_d(_selectedDay!));
                              });

                              await _loadWorkDays();


                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                  content: Text('تم إلغاء الإجازة'),
                                  duration: Duration(seconds: 2),
                                ));
                            } else {
                              await FirebaseFirestore.instance.collection('Appointments').add({
                                'lawyerId': currentUser.uid,
                                'userId': null,
                                'date': dateStr,
                                'time': null,
                                'isAvailable': false,
                                'isHoliday': true,
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              setState(() {
                                _holidayDates.add(_d(_selectedDay!));
                              });

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                  content: Text('تم تحديد اليوم كإجازة'),
                                  duration: Duration(seconds: 2),
                                ));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B7D73),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          ),
                          child: Text(
                            _isHolidayDay(_selectedDay) ? 'إلغاء الإجازة' : 'إجازة',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('مواعيد الاستشارات', style: TextStyle(color: Color(0xFF052532) , fontSize: 18,fontWeight: FontWeight.bold,)),
                  ),
                ],
              ),
            ),


          Expanded(
            child: Builder(
              builder: (context) {
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                if (currentUid == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _hasAnyCards != false) {
                      setState(() => _hasAnyCards = false);
                    }
                  });
                  return const Center(child: Text('لا توجد مواعيد'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Consultations')
                      .where('selected_lawyer_uid', isEqualTo: currentUid)

                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _hasAnyCards != false) {
                          setState(() => _hasAnyCards = false);
                        }
                      });
                      return const Center(child: Text('لا توجد مواعيد'));
                    }

                    final docs = snap.data!.docs.where((doc) {
                      final d = Map<String, dynamic>.from(doc.data() as Map);
                      final appt = Map<String, dynamic>.from((d['appointment'] ?? {}) as Map);
                      final dateStr = (appt['date'] ?? '').toString();
                      final timeStr = (appt['time'] ?? '').toString();
                      return dateStr.isNotEmpty && timeStr.isNotEmpty;
                    }).toList();


                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _hasAnyCards != docs.isNotEmpty) {
                        setState(() => _hasAnyCards = docs.isNotEmpty);
                      }
                    });


                    docs.sort((a, b) {
                      final aMap = Map<String, dynamic>.from(a.data() as Map);
                      final bMap = Map<String, dynamic>.from(b.data() as Map);
                      final am = Map<String, dynamic>.from((aMap['appointment'] ?? {}) as Map);
                      final bm = Map<String, dynamic>.from((bMap['appointment'] ?? {}) as Map);

                      final ad = (am['date'] ?? '').toString();
                      final bd = (bm['date'] ?? '').toString();
                      final at = (am['time'] ?? '').toString();
                      final bt = (bm['time'] ?? '').toString();
                      final c1 = ad.compareTo(bd);
                      return c1 != 0 ? c1 : at.compareTo(bt);
                    });

                    if (docs.isEmpty) {
                      return const Center(child: Text('لا توجد مواعيد'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final data = Map<String, dynamic>.from(docs[i].data() as Map);
                        final appt = Map<String, dynamic>.from((data['appointment'] ?? {}) as Map);

                        final type = (data['type'] ?? '').toString();
                        final userUid = (data['user_uid'] ?? '').toString();
                        final dateStr = (appt['date'] ?? '').toString();
                        final timeStr = (appt['time'] ?? '').toString();

                        return Container(
                          key: ValueKey(docs[i].id),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B7D73),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),

                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  'نوع الاستشارة: ${type.isNotEmpty ? type : '—'}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),


                                _UserNameLine(userUid: userUid),
                                const SizedBox(height: 6),


                                Text(
                                  'التاريخ: ${_fmtDate(dateStr)}   •   الوقت: ${timeStr.isNotEmpty ? timeStr : '—'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}


class _UserNameLine extends StatelessWidget {
  final String userUid;
  const _UserNameLine({Key? key, required this.userUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userUid.isEmpty) {
      return const Text('العميل: مستخدم', style: TextStyle(color: Colors.white));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Individual').doc(userUid).get(),
      builder: (context, userSnap) {
        final userMap = (userSnap.hasData && userSnap.data!.exists)
            ? Map<String, dynamic>.from(userSnap.data!.data() as Map)
            : null;
        final userName = userMap?['display_name']?.toString() ?? 'مستخدم';

        return Text('العميل: $userName', style: const TextStyle(color: Colors.white));
      },
    );
  }
}
