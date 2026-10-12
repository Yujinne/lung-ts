//약
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineAlarmScreen extends StatefulWidget {
  @override
  _MedicineAlarmScreenState createState() => _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState extends State<MedicineAlarmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? drugInfo;
  bool isLoading = false;
  List<Map<String, dynamic>> favoriteDrugs = [];
  List<String> favoriteDrugNames = []; // 즐겨찾기된 약 이름만 저장
  List<String> repeatDays = ['월', '화', '수', '목', '금', '토', '일'];
  TimeOfDay selectedTime = TimeOfDay.now();
  String alarmName = '';
  bool isVibrate = false;
  List<String> selectedRepeatDays = [];
  List<Map<String, dynamic>> alarms = [];
  List<Map<String, dynamic>> autoAlarms = [];
  int? selectedTimesPerDay;
  List<String> selectedAutoPeriods = [];
  bool isDeleteMode = false;
  Set<int> selectedDeleteIndices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
    _loadAlarmsFromFirestore(); // ← 추가
  }

  Future<void> _loadAlarmsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // 수동 알람 불러오기
    final manualSnap = await docRef.collection('medicine_alarms').doc('manual').get();
    if (manualSnap.exists) {
      final data = manualSnap.data();
      final List manualList = data?['alarms'] ?? [];

      alarms = manualList.map<Map<String, dynamic>>((alarm) {
        final timeParts = (alarm['time'] as String).split(':');
        return {
          'name': alarm['name'],
          'time': TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
          'days': List<String>.from(alarm['days']),
          'vibrate': alarm['vibrate'],
        };
      }).toList();
    }

    // 자동 알람 불러오기
    final autoSnap = await docRef.collection('medicine_alarms').doc('auto').get();
    if (autoSnap.exists) {
      final data = autoSnap.data();
      final List autoList = data?['autoAlarms'] ?? [];

      autoAlarms = autoList.map<Map<String, dynamic>>((alarm) {
        return {
          'times': alarm['times'],
          'periods': List<String>.from(alarm['periods']),
        };
      }).toList();
    }

    setState(() {}); // UI 갱신
  }



  Future<void> _searchDrugInfo() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final uri = Uri.parse(
        'http://localhost:8080/api/medicines/search',
      ).replace(
        queryParameters: {
          'name': query,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        _showDrugBottomSheet(data);
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('검색 결과가 없습니다.'),
          ),
        );
      } else {
        throw Exception(
          '약 정보 조회 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('약 검색 오류: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('약 정보를 불러오지 못했습니다.'),
        ),
      );
    }
  }

  void _showDrugBottomSheet(Map<String, dynamic> drug) {
    final itemName = drug['itemName'] ?? '';
    final scrollController = ScrollController(); // ✅ 추가

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          bool isFavorited = favoriteDrugNames.contains(itemName);

          return SingleChildScrollView(
            controller: scrollController, // ✅ 연결
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(itemName),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorited ? Icons.star : Icons.star_border,
                      color: isFavorited ? Colors.amber : null,
                    ),
                    onPressed: () async {
                      if (isFavorited) {
                        await _removeFromFavorites(itemName);
                      } else {
                        await _addToFavorites(drug);
                      }
                      await _loadFavorites();

                      setStateBottomSheet(() {}); // rebuild

                      // ✅ 별 누르면 자동 스크롤
                      await Future.delayed(Duration(milliseconds: 150));
                      if (scrollController.hasClients) {
                        scrollController.animateTo(
                          scrollController.offset + 80,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (drug['itemImage'] != null)
                        Image.network(drug['itemImage'], height: 120),
                      const SizedBox(height: 16),
                      const Text('효능효과', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(drug['efcyQesitm'] ?? '정보 없음'),
                      const SizedBox(height: 16),
                      const Text('용법용량', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(drug['useMethodQesitm'] ?? '정보 없음'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicine_favorites')
        .get();

    setState(() {
      favoriteDrugs = snapshot.docs.map((doc) => doc.data()).toList();
      favoriteDrugNames = favoriteDrugs.map((e) => e['itemName'] as String).toList();
    });
  }


  void _showFavoriteDetail(Map<String, dynamic> drug) {
    _showDrugBottomSheet(drug);
  }

  Future<void> _addToFavorites(Map<String, dynamic> drug) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final itemName = drug['itemName'];
    if (itemName == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicine_favorites')
        .doc(itemName);

    await docRef.set(drug);

    // 리스트에 추가
    if (!favoriteDrugNames.contains(itemName)) {
      setState(() {
        favoriteDrugNames.add(itemName);
      });
    }

    await _loadFavorites(); // 전체 즐겨찾기 다시 불러오기
  }

  Future<void> _removeFromFavorites(String itemName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicine_favorites')
        .doc(itemName);

    await docRef.delete();

    await _loadFavorites();

    setState(() {
      favoriteDrugNames.remove(itemName);
      favoriteDrugs.removeWhere((drug) => drug['itemName'] == itemName);
    });
  }


  void _showTimePickerDialog(
      {Map<String, dynamic>? alarmToEdit, int? indexToEdit}) {
    TimeOfDay time = alarmToEdit?['time'] ?? TimeOfDay.now();
    List<String> days = alarmToEdit?['days'] ?? [];
    String name = alarmToEdit?['name'] ?? '';
    bool vibrate = alarmToEdit?['vibrate'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('알람 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setStateDialog(() => time = picked);
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.access_time),
                        SizedBox(width: 8),
                        Text('${time.format(context)}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    children: repeatDays.map((day) {
                      final selected = days.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: selected,
                        onSelected: (bool selected) {
                          setStateDialog(() {
                            if (selected) {
                              days.add(day);
                            } else {
                              days.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(labelText: '원하는 알람 이름'),
                    controller: TextEditingController(text: name),
                    onChanged: (value) => name = value,
                  ),
                  SwitchListTile(
                    title: Text('진동'),
                    value: vibrate,
                    onChanged: (value) {
                      setStateDialog(() => vibrate = value);
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context), child: Text('취소')),
                TextButton(
                  onPressed: () {
                    // 요일 정렬
                    final sortedDays = repeatDays
                        .where((d) => days.contains(d))
                        .toList();

                    final newAlarm = {
                      'time': time,
                      'days': sortedDays,
                      'name': name,
                      'vibrate': vibrate,
                    };
                    setState(() {
                      if (indexToEdit != null) {
                        alarms[indexToEdit] = newAlarm;
                      } else {
                        alarms.add(newAlarm);
                      }
                    });
                    Navigator.pop(context);
                    _saveAlarmsToFirestore();
                  },
                  child: Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSelectedAlarms() {
    setState(() {
      alarms = alarms
          .asMap()
          .entries
          .where((entry) => !selectedDeleteIndices.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      selectedDeleteIndices.clear();
      isDeleteMode = false;
    });
    _saveAlarmsToFirestore();
  }

  void _deleteAutoAlarm() {
    setState(() {
      autoAlarms.clear();
    });
    _saveAlarmsToFirestore();
  }

  Future<void> _saveAlarmsToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // 수동 알람 저장
    final manualRef = docRef.collection('medicine_alarms').doc('manual');
    await manualRef.set({
      'alarms': alarms.map((a) => {
        'name': a['name'],
        'time': '${a['time'].hour.toString().padLeft(2, '0')}:${a['time'].minute.toString().padLeft(2, '0')}',
        'days': a['days'],
        'vibrate': a['vibrate'],
      }).toList(),
    });

    // 자동 알람 저장
    final autoRef = docRef.collection('medicine_alarms').doc('auto');
    await autoRef.set({
      'autoAlarms': autoAlarms,
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('약'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '복용관리'),
            Tab(text: '알람설정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 복용관리 탭
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '약 이름 검색',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchDrugInfo,
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteDrugs.length,
                  itemBuilder: (context, index) {
                    final drug = favoriteDrugs[index];
                    return ListTile(
                      title: Text(drug['itemName'] ?? ''),
                      leading: drug['itemImage'] != null
                          ? Image.network(drug['itemImage'], width: 50)
                          : null,
                      onTap: () => _showFavoriteDetail(drug),
                    );
                  },
                ),
              ),
            ],
          ),

          // 알람설정 탭
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('자동설정', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    DropdownButton<int>(
                      hint: Text('일 3회'),
                      value: selectedTimesPerDay,
                      items: List.generate(5, (i) => i + 1).map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text('일 $e회'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedTimesPerDay = val;
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('아침/저녁'),
                      selected: selectedAutoPeriods.contains('아침/저녁'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedAutoPeriods.add('아침/저녁');
                          } else {
                            selectedAutoPeriods.remove('아침/저녁');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('점심'),
                      selected: selectedAutoPeriods.contains('점심'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedAutoPeriods.add('점심');
                          } else {
                            selectedAutoPeriods.remove('점심');
                          }
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedTimesPerDay != null ||
                            selectedAutoPeriods.isNotEmpty) {
                          setState(() {
                            autoAlarms.clear();
                            autoAlarms.add({
                              'times': selectedTimesPerDay,
                              'periods': List<String>.from(selectedAutoPeriods),
                            });
                          });
                          _saveAlarmsToFirestore();
                        }
                      },
                      child: Text('확인'),
                    )
                  ],
                ),
                if (autoAlarms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: autoAlarms.map((alarm) {
                        final periods = alarm['periods']?.join(', ') ?? '';
                        return ListTile(
                          title: Text('자동 알람'),
                          subtitle: Text(
                              '${alarm['times'] != null ? '일 ${alarm['times']}회, ' : ''}시간대: $periods'
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: _deleteAutoAlarm,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('수동설정', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _showTimePickerDialog(),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              isDeleteMode = !isDeleteMode;
                              selectedDeleteIndices.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (isDeleteMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _deleteSelectedAlarms,
                      child: Text('선택 삭제'),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarms[index];
                      final isSelected = selectedDeleteIndices.contains(index);
                      return ListTile(
                        leading: isDeleteMode
                            ? Checkbox(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedDeleteIndices.add(index);
                              } else {
                                selectedDeleteIndices.remove(index);
                              }
                            });
                          },
                        )
                            : null,
                        title: Text(alarm['name'] ?? ''),
                        subtitle: Text('${alarm['time'].format(
                            context)} | ${alarm['days'].join(', ')}'),
                        trailing: isDeleteMode ? null : Icon(Icons.edit),
                        onTap: isDeleteMode
                            ? () {
                          setState(() {
                            if (isSelected) {
                              selectedDeleteIndices.remove(index);
                            } else {
                              selectedDeleteIndices.add(index);
                            }
                          });
                        }
                            : () =>
                            _showTimePickerDialog(alarmToEdit: alarm,
                                indexToEdit: index),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
