import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'diary_screen.dart';
import 'diary_detail.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<Map<String, dynamic>> diaryEntries = [];

  bool isDeleting = false;
  bool isMenuOpen = false;
  bool isProcessing = false;

  Set<int> selectedEntries = <int>{};

  static const Color primaryBlue = Color(0xFF377DCE);
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF202936);
  static const Color textGray = Color(0xFF8B929D);
  static const Color _dark = Color(0xFF202936);

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

      final List<dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final results = data.map((item) {
        final occurredAt = DateTime.parse(item['occurredAt']);

        return <String, dynamic>{
          'id': item['id'],
          'date': DateFormat('yy/MM/dd').format(occurredAt),
          'time':
          '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}',
          'symptoms': List<String>.from(item['symptoms'] ?? []),
          'memo': item['memo'] ?? '',
          'createdAt': item['createdAt'],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        diaryEntries = results;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일기를 불러오지 못했습니다: $e'),
        ),
      );
    }
  }

  Future<void> _openDiary({
    Map<String, dynamic>? entry,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryScreen(
          onSave: (_) {},
          initialData: entry == null
              ? null
              : {
            ...entry,
            'symptoms':
            (entry['symptoms'] as List).join(', '),
          },
        ),
      ),
    );

    if (!mounted) return;

    if (result == true || entry == null) {
      await _loadDiaries();
    }
  }

  Future<void> _viewDiary(Map<String, dynamic> entry) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryDetailScreen(entry: entry),
      ),
    );

    if (!mounted) return;
    await _loadDiaries();
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void _startDeleteMode() {
    setState(() {
      isMenuOpen = false;
      isDeleting = true;
      selectedEntries.clear();
    });
  }

  void _cancelDeleteMode() {
    setState(() {
      isDeleting = false;
      selectedEntries.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (selectedEntries.contains(id)) {
        selectedEntries.remove(id);
      } else {
        selectedEntries.add(id);
      }
    });
  }

  Future<void> _deleteSelectedEntries() async {
    if (selectedEntries.isEmpty || isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Color(0xFFE45252),
              ),
              SizedBox(width: 10),
              Text('일기 삭제'),
            ],
          ),
          content: Text(
            '선택한 일기 ${selectedEntries.length}개를 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text(
                '취소',
                style: TextStyle(color: textGray),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Color(0xFFE45252),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final idsToDelete = selectedEntries.toList();

      for (final id in idsToDelete) {
        final response = await http.delete(
          Uri.parse('http://localhost:8080/api/diaries/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode != 200 &&
            response.statusCode != 204) {
          throw Exception(
            '일기 삭제 실패: $id (${response.statusCode})',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        selectedEntries.clear();
        isDeleting = false;
      });

      await _loadDiaries();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선택한 일기가 삭제되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildDiaryCard(
      Map<String, dynamic> entry,
      int index,
      ) {
    final int id = entry['id'] as int;
    final bool isSelected = selectedEntries.contains(id);

    return TweenAnimationBuilder<double>(
      key: ValueKey(id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 300 + (index.clamp(0, 5) * 50),
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 15),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: isDeleting
                ? () => _toggleSelection(id)
                : () => _viewDiary(entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              child: Row(
                children: [
                  if (isDeleting) ...[
                    Checkbox(
                      value: isSelected,
                      activeColor: primaryBlue,
                      onChanged: (_) => _toggleSelection(id),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry['date']}  ${entry['time']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '증상: ${(entry['symptoms'] as List).join(', ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!isDeleting)
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF9CA3AF),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDanger
                    ? const Color(0xFFE45252)
                    : primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDanger
                      ? const Color(0xFFE45252)
                      : textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
      if (isMenuOpen) {
        setState(() {
          isMenuOpen = false;
        });
      }
    },
    child: Scaffold(
    backgroundColor: pageBackground,
    appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        title: const Text(
          '일기장',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: diaryEntries.isEmpty
          ? const Center(
        child: Text(
          '작성된 일기가 없습니다.',
          style: TextStyle(
            color: textGray,
            fontSize: 14,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          20, 20, 20, 100,
        ),
        itemCount: diaryEntries.length,
        itemBuilder: (context, index) {
          return _buildDiaryCard(
            diaryEntries[index],
            index,
          );
        },
      ),

      floatingActionButton: isDeleting
          ? null
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isMenuOpen
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMenuButton(
                  icon: Icons.delete_outline,
                  title: '일기 삭제',
                  isDanger: true,
                  onTap: _startDeleteMode,
                ),
                const SizedBox(height: 10),
                _buildMenuButton(
                  icon: Icons.add,
                  title: '일기 쓰기',
                  onTap: () {
                    setState(() {
                      isMenuOpen = false;
                    });
                    _openDiary();
                  },
                ),
                const SizedBox(height: 12),
              ],
            )
                : const SizedBox.shrink(),
          ),

          FloatingActionButton(
            heroTag: 'diaryEditFab',
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: _toggleMenu,
            child: Icon(
              isMenuOpen ? Icons.close : Icons.edit_outlined,
              size: 24,
            ),
          ),
        ],
      ),

      bottomNavigationBar: isDeleting
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20, 12, 20, 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing
                      ? null
                      : _cancelDeleteMode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textGray,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedEntries.isNotEmpty &&
                      !isProcessing
                      ? _deleteSelectedEntries
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE45252),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isProcessing
                        ? '삭제 중...'
                        : '삭제 (${selectedEntries.length})',
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    ),
    );
  }
}
