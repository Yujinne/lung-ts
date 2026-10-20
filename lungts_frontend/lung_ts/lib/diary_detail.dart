import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'diary_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  static const _blue = Color(0xFF377DCE);
  static const _dark = Color(0xFF202936);
  bool _changed = false;
  late Map<String, dynamic> _entry;

  @override
  void initState() {
    super.initState();
    _entry = Map<String, dynamic>.from(widget.entry);
  }

  Future<void> _reloadEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('로그인 정보가 없습니다.');

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/diaries'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('일기 조회 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    final matching = data.cast<Map<String, dynamic>>().where(
          (item) => item['id'].toString() == _entry['id'].toString(),
    );
    if (matching.isEmpty) throw Exception('수정된 일기를 찾을 수 없습니다.');

    final item = matching.first;
    final occurredAt = DateTime.parse(item['occurredAt'].toString());
    if (!mounted) return;
    setState(() {
      _entry = {
        'id': item['id'],
        'date': DateFormat('yy/MM/dd').format(occurredAt),
        'time': '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}',
        'symptoms': List<String>.from(item['symptoms'] ?? []),
        'memo': item['memo'] ?? '',
        'createdAt': item['createdAt'],
      };
    });
  }

  Future<void> _editDiary() async {
    final entry = _entry;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryScreen(
          onSave: (_) {},
          initialData: {
            ...entry,
            'symptoms': (entry['symptoms'] as List).join(', '),
          },
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _changed = true;
      try {
        await _reloadEntry();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정한 일기를 다시 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final date = DateFormat('yy/MM/dd').parse(entry['date'] as String);
    final symptoms = List<String>.from(entry['symptoms'] as List);
    final memo = (entry['memo'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('일기 상세', style: TextStyle(
          color: _dark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () => Navigator.pop(context, _changed),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(Icons.event_note_outlined, '증상 일시'),
                              const SizedBox(height: 16),
                              Text(DateFormat('yyyy년 M월 d일').format(date),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _dark)),
                              const SizedBox(height: 6),
                              Text(entry['time'].toString(), style: const TextStyle(fontSize: 14, color: Color(0xFF7A8492))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(Icons.favorite_border, '증상 종류'),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: symptoms.map((symptom) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF3FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(symptom, style: const TextStyle(color: _blue, fontSize: 13, fontWeight: FontWeight.w600)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(Icons.edit_note_outlined, '메모'),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 100),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  memo.isEmpty ? '작성된 메모가 없습니다.' : memo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.7,
                                    color: memo.isEmpty
                                        ? const Color(0xFF9CA3AF)
                                        : _dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _editDiary,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      label: const Text('수정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _heading(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: _blue, size: 21),
      const SizedBox(width: 9),
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
    ],
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );
}
