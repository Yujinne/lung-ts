import 'package:flutter/material.dart';

class AppCalendar {
  static Future<DateTime?> show(
      BuildContext context, {
        DateTime? initialDate,
        DateTime? firstDate,
        DateTime? lastDate,
        Set<DateTime> markedDates = const {},
      }) async {
    final now = DateTime.now();
    final initial = initialDate ?? now;
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime selected = initial;
        DateTime displayedMonth = DateTime(initial.year, initial.month);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final firstWeekday =
                DateTime(displayedMonth.year, displayedMonth.month, 1)
                    .weekday % 7;

            final daysInMonth =
                DateTime(displayedMonth.year, displayedMonth.month + 1, 0)
                    .day;

            final monthStart = DateTime(
              displayedMonth.year,
              displayedMonth.month,
            );

            final canPrevious = monthStart.isAfter(
              DateTime(first.year, first.month),
            );

            final canNext = monthStart.isBefore(
              DateTime(last.year, last.month),
            );

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${displayedMonth.year}년 ${displayedMonth.month}월',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: canPrevious
                              ? () => setDialogState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month - 1,
                            );
                          })
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: canNext
                              ? () => setDialogState(() {
                            displayedMonth = DateTime(
                              displayedMonth.year,
                              displayedMonth.month + 1,
                            );
                          })
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: List.generate(7, (index) {
                        const weekdays = [
                          '일', '월', '화', '수', '목', '금', '토'
                        ];

                        return Expanded(
                          child: Center(
                            child: Text(
                              weekdays[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: index == 0
                                    ? const Color(0xFFE65A6A)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstWeekday) {
                          return const SizedBox.shrink();
                        }

                        final day = index - firstWeekday + 1;
                        final date = DateTime(
                          displayedMonth.year,
                          displayedMonth.month,
                          day,
                        );

                        final isSelected =
                            selected.year == date.year &&
                                selected.month == date.month &&
                                selected.day == date.day;

                        final isToday =
                            now.year == date.year &&
                                now.month == date.month &&
                                now.day == date.day;

                        final hasMarker = markedDates.any(
                              (markedDate) =>
                          markedDate.year == date.year &&
                              markedDate.month == date.month &&
                              markedDate.day == date.day,
                        );

                        final enabled =
                            !date.isBefore(DateTime(
                              first.year, first.month, first.day,
                            )) &&
                                !date.isAfter(DateTime(
                                  last.year, last.month, last.day,
                                ));

                        return InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: enabled
                              ? () => setDialogState(() {
                            selected = date;
                          })
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3977E8)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !enabled
                                        ? const Color(0xFFD1D5DB)
                                        : isSelected
                                        ? Colors.white
                                        : index % 7 == 0
                                        ? const Color(0xFFE65A6A)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                                if (hasMarker)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF76C5F5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                else if (isToday)
                                  Text(
                                    '오늘',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF3977E8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, selected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3977E8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('선택'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}