import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'widgets/app_calendar.dart';

import 'diary_screen.dart';
import 'diary_detail.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<Map<String, dynamic>> diaryEntries = [];
  DateTime _selectedDate = DateTime.now();

  late final PageController _weekPageController;

  static const int _initialWeekPage = 10000;
  late final DateTime _baseWeekStart;

  DateTime get _weekStart {
    final date = _selectedDate;
    return DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _hasDiaryOnDate(DateTime date) {
    return diaryEntries.any((entry) {
      final diaryDate = DateFormat('yy/MM/dd').parse(entry['date'] as String);
      return _isSameDate(diaryDate, date);
    });
  }

  List<Map<String, dynamic>> get _filteredDiaries {
    return diaryEntries.where((entry) {
      final date = DateFormat('yy/MM/dd').parse(entry['date'] as String);
      return _isSameDate(date, _selectedDate);
    }).toList();
  }

  DateTime _weekStartForPage(int page) {
    return _baseWeekStart.add(
      Duration(days: (page - _initialWeekPage) * 7),
    );
  }

  int _pageForDate(DateTime date) {
    final targetMonday = DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );

    return _initialWeekPage +
        targetMonday.difference(_baseWeekStart).inDays ~/ 7;
  }

  Future<void> _openCalendar() async {
    final markedDates = diaryEntries.map((entry) {
      return DateFormat('yy/MM/dd').parse(entry['date'] as String);
    }).toSet();

    final date = await AppCalendar.show(
      context,
      initialDate: _selectedDate,
      markedDates: markedDates,
    );

    if (date == null || !mounted) return;

    setState(() {
      _selectedDate = date;
    });

    await _weekPageController.animateToPage(
      _pageForDate(date),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  bool isDeleting = false;
  bool isMenuOpen = false;
  bool isProcessing = false;

  Set<int> selectedEntries = <int>{};

  static const Color primaryBlue = Color(0xFF377DCE);
  static const Color pageBackground = Color(0xFFF9FAFB);
  static const Color textDark = Color(0xFF202936);
  static const Color textGray = Color(0xFF8B929D);
  static const Color _dark = Color(0xFF202936);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _baseWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    _weekPageController = PageController(
      initialPage: _initialWeekPage,
    );

    _loadDiaries();
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    super.dispose();
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
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildWeekCalendar() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _openCalendar,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM d, yyyy', 'en_US')
                      .format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 13,
                    color: textGray,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: primaryBlue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _isSameDate(_selectedDate, today)
                ? 'Today'
                : DateFormat('EEEE', 'en_US').format(_selectedDate),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 86,
            child: PageView.builder(
              controller: _weekPageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (page) {
                final weekStart = _weekStartForPage(page);
                final weekdayIndex = _selectedDate.weekday - 1;

                setState(() {
                  _selectedDate = weekStart.add(
                    Duration(days: weekdayIndex),
                  );
                });
              },
              itemBuilder: (context, page) {
                final weekStart = _weekStartForPage(page);

                return Row(
                  children: List.generate(7, (index) {
                    final date = weekStart.add(
                      Duration(days: index),
                    );

                    final selected = _isSameDate(
                      date,
                      _selectedDate,
                    );

                    final isToday = _isSameDate(date, today);

                    final hasDiary = _hasDiaryOnDate(date);

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              weekdays[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? primaryBlue
                                    : textGray,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? primaryBlue
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : textDark,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            SizedBox(
                              height: 8,
                              child: hasDiary
                                  ? Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF76C5F5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildWeekCalendar(),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _filteredDiaries.isEmpty
                ? const Center(
              child: Text(
                '선택한 날짜에 작성된 일기가 없습니다.',
                style: TextStyle(
                  color: textGray,
                  fontSize: 14,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              itemCount: _filteredDiaries.length,
              itemBuilder: (context, index) {
                return _buildDiaryCard(
                  _filteredDiaries[index],
                  index,
                );
              },
            ),
          ),
        ],
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
