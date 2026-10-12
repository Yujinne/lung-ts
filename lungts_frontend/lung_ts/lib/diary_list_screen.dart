import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'diary_screen.dart';
import 'package:intl/intl.dart';
import 'package:lung_ts/app_colors.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  _DiaryListScreenState createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<Map<String, dynamic>> diaryEntries = [];
  bool isDeleting = false;
  Set<int> selectedEntries = <int>{};

  final Duration _animationDelay = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/diaries'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('일기 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      final results = data.map((item) {
        final DateTime occurredAt =
        DateTime.parse(item['occurredAt']);

        return <String, dynamic>{
          'id': item['id'],
          'date': DateFormat('yy/MM/dd').format(occurredAt),
          'time':
          '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}',
          'symptoms': List<String>.from(item['symptoms']),
          'memo': item['memo'] ?? '',
          'createdAt': item['createdAt'],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        diaryEntries = results;
      });
    } catch (e) {
      print('일기 조회 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일기를 불러오지 못했습니다: $e'),
        ),
      );
    }
  }

  Future<void> _deleteSelectedEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      // 선택된 일기의 id들 가져오기
      final idsToDelete = selectedEntries
          .map((index) => diaryEntries[index]['id'])
          .toList();

      // 선택된 일기 하나씩 삭제
      for (final id in idsToDelete) {
        final response = await http.delete(
          Uri.parse('http://localhost:8080/api/diaries/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode != 200) {
          throw Exception(
            '일기 삭제 실패: $id (${response.statusCode})',
          );
        }
      }

      // 삭제 완료 후 Spring에서 목록 다시 조회
      await _loadDiaries();

      if (!mounted) return;

      setState(() {
        selectedEntries.clear();
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 일기가 삭제되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $e'),
        ),
      );
    }
  }

  void _toggleDeleteMode() {
    setState(() {
      isDeleting = !isDeleting;
      selectedEntries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("일기장"),
        actions: [
          IconButton(
            icon: Icon(isDeleting ? Icons.delete : Icons.delete_outline),
            onPressed: _toggleDeleteMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: diaryEntries.isEmpty
                ? const Center(child: Text("작성된 일기가 없습니다."))
                : ListView.builder(
              itemCount: diaryEntries.length,
                itemBuilder: (context, index) {
                  final entry = diaryEntries[index];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: isDeleting
                            ? Checkbox(
                          value: selectedEntries.contains(index),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedEntries.add(index);
                              } else {
                                selectedEntries.remove(index);
                              }
                            });
                          },
                        )
                            : null,
                        title: Text("${entry["date"]} ${entry["time"]}"),
                        subtitle: Text("증상: ${(entry["symptoms"] as List).join(", ")}"),
                        onTap: isDeleting
                            ? () {
                          setState(() {
                            if (selectedEntries.contains(index)) {
                              selectedEntries.remove(index);
                            } else {
                              selectedEntries.add(index);
                            }
                          });
                        }
                            : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiaryScreen(
                                onSave: (_) {},
                                initialData: {
                                  ...entry,
                                  'symptoms':
                                  (entry['symptoms'] as List).join(', '),
                                },
                              ),
                            ),
                          );

                          if (result == true) {
                            await _loadDiaries();
                          }
                        },
                      ),
                    ),
                  );
                }


            ),
          ),
          if (isDeleting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedEntries.isNotEmpty
                      ? _deleteSelectedEntries
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("삭제",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          if (!isDeleting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DiaryScreen(onSave: (_) {}),
                      ),
                    );
                    // 일기 저장하고 돌아오면 다시 데이터 불러오기
                    await _loadDiaries();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlueBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("일기 쓰기",
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
