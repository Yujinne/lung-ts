// 음성 측정 기록
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';


class LungLogScreen extends StatefulWidget {
  @override
  State<LungLogScreen> createState() => _LungLogScreenState();

}

class _LungLogScreenState extends State<LungLogScreen> {
  Set<DateTime> measuredDates = {};
  Map<String, List<Map<String, dynamic>>> fileTimes = {};

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  //재생 상태 관리 변수
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingKey; // 현재 재생 중인 time key
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isPaused = false;

  Map<String, Duration> _pausedPositions = {};


  @override
  void initState() {
    super.initState();
    _loadVoiceLogs();

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingKey = null;
          _position = Duration.zero;
        });
      }
    });
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getTimesForDay(DateTime day) {
    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    return fileTimes[key] ?? [];
  }

  void _goToPreviousMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month + 1);
    });
  }
  void _selectYearMonth() {
    final int currentYear = focusedDay.year;
    final int currentMonthValue = focusedDay.month;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = currentYear;
        int selectedMonth = currentMonthValue;

        return SizedBox(
          height: 250,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: currentYear - 2000,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedYear = 2000 + index;
                        },
                        children: List.generate(50, (index) {
                          return Center(
                            child: Text('${2000 + index}년'),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: currentMonthValue - 1,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedMonth = index + 1;
                        },
                        children: List.generate(12, (index) {
                          return Center(
                            child: Text('${index + 1}월'),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    focusedDay = DateTime(selectedYear, selectedMonth);
                    selectedDay = DateTime(selectedYear, selectedMonth, 1);
                  });
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadVoiceLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인 정보가 없습니다.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/lung-sounds'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          '음성 측정 기록 조회 실패: ${response.statusCode}',
        );
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final Map<String, List<Map<String, dynamic>>> newFileTimes = {};
      final Set<DateTime> newMeasuredDates = {};

      for (final item in data) {
        final recordedAtString = item['recordedAt'];

        if (recordedAtString == null) {
          continue;
        }

        final recordedAt = DateTime.parse(recordedAtString);

        final year = recordedAt.year;
        final month = recordedAt.month;
        final day = recordedAt.day;

        newMeasuredDates.add(
          DateTime(year, month, day),
        );

        final dateKey =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(
            2, '0')}';

        final time =
            '${recordedAt.hour.toString().padLeft(2, '0')}'
            '${recordedAt.minute.toString().padLeft(2, '0')}';

        newFileTimes.putIfAbsent(dateKey, () => []);

        newFileTimes[dateKey]!.add({
          'id': item['id'],
          'time': time,
        });
      }

      if (!mounted) return;

      setState(() {
        measuredDates = newMeasuredDates;
        fileTimes = newFileTimes;
      });
    } catch (e) {
      print('음성 측정 기록 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        measuredDates = {};
        fileTimes = {};
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }


  @override
  Widget build(BuildContext context) {
    final times = getTimesForDay(selectedDay);
    final selectedKey = "${selectedDay.year}-${selectedDay.month
        .toString()
        .padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

    return Container(
      color: const Color(0xFFF9FAFB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 이전/다음 월 이동 버튼
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  color: const Color(0xFF3678C8),
                ),
                InkWell(
                  onTap: _selectYearMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${focusedDay.year}년 ${focusedDay.month.toString().padLeft(2, '0')}월',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 19,
                          color: Color(0xFF3678C8),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _goToNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  color: const Color(0xFF3678C8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TableCalendar(
                  onPageChanged: (day) {
                    setState(() {
                      focusedDay = day;
                    });
                  },
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                  headerVisible: false,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      bool isMeasured = measuredDates.any((d) =>
                          isSameDay(d, day));
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isMeasured
                              ? Colors.amberAccent.shade100
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${day.day}'),
                      );
                    },
                  ),
                ),

                const Divider(height: 24),

                if (times.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('선택한 날짜에 저장된 음성이 없습니다.'),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: times.length,
                      itemBuilder: (context, index) {
                        final record = times[index];
                        final int resultId = (record['id'] as num).toInt();
                        final String time = record['time'] as String;
                        final formatted = "${time.substring(0, 2)}:${time
                            .substring(2)}";
                        final isPlaying = _playingKey == time;
                        final isSelected = _playingKey == time;
                        final isActuallyPlaying = isSelected &&
                            _audioPlayer.playing;


                        // 가정: 저장된 경로는 이와 같은 형식임. 필요 시 수정
                        final datePath = selectedKey.replaceAll(
                            '-', '.'); // "2025.05.14"
                        final voiceUrl =
                            'http://localhost:8080/api/lung-sounds/$resultId/audio';

                        return Column(
                          children: [
                            ListTile(
                              title: Text("$formatted 측정 음성"),
                              trailing: IconButton(

                                  icon: Icon(
                                      isActuallyPlaying ? Icons.pause : Icons
                                          .play_arrow),
                                  onPressed: () async {
                                    if (isActuallyPlaying) {
                                      // 재생 중 → 일시정지
                                      await _audioPlayer.pause();
                                      // 정확한 위치를 스트림에서 한 번 가져옴
                                      final currentPos = await _audioPlayer
                                          .positionStream.first;

                                      setState(() {
                                        _isPaused = true;
                                        _pausedPositions[_playingKey!] =
                                            currentPos;
                                      });
                                    } else if (isSelected && _isPaused) {
                                      final pausedPos = _pausedPositions[_playingKey!];
                                      if (pausedPos != null) {
                                        await _audioPlayer.seek(pausedPos);
                                      }
                                      await _audioPlayer.play();
                                      setState(() {
                                        _isPaused = false;
                                      });
                                    } else {
                                      try {
                                        // 새로운 항목 재생: 기존 오디오 정지하고 새 URL 설정
                                        await _audioPlayer.stop();

                                        setState(() {
                                          _playingKey = time;
                                          _position = Duration.zero;
                                          _duration = Duration.zero;
                                          _isPaused = false;
                                        });
                                        _pausedPositions.removeWhere((key,
                                            _) => key != time);

                                        final prefs = await SharedPreferences.getInstance();
                                        final token = prefs.getString('jwt_token');

                                        if (token == null) {
                                          throw Exception('로그인이 필요합니다.');
                                        }

                                        final response = await http.get(
                                          Uri.parse(voiceUrl),
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                          },
                                        );

                                        if (response.statusCode != 200) {
                                          throw Exception('WAV 파일 조회 실패: ${response.statusCode}');
                                        }

                                        final audioBytes = Uint8List.fromList(response.bodyBytes);

                                        await _audioPlayer.setAudioSource(
                                          _WavAudioSource(audioBytes),
                                        );

                                        final duration = await _audioPlayer
                                            .durationFuture;
                                        if (duration != null) {
                                          setState(() {
                                            _duration = duration;
                                          });
                                        }

                                        await _audioPlayer.play();
                                      } catch (e) {
                                        print("오디오 재생 에러: $e");
                                      }
                                    }
                                  }


                              ),

                            ),
                            if (isPlaying)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Column(
                                  children: [
                                    Slider(
                                      min: 0,
                                      max: _duration.inSeconds.toDouble(),
                                      value: _position.inSeconds.toDouble().clamp(
                                          0, _duration.inSeconds.toDouble()),
                                      onChanged: (value) {
                                        setState(() {
                                          _position =
                                              Duration(seconds: value.toInt());
                                        });
                                      },
                                      onChangeEnd: (value) async {
                                        final newPosition = Duration(
                                            seconds: value.toInt());
                                        await _audioPlayer.seek(newPosition);

                                        if (_playingKey != null) {
                                          _pausedPositions[_playingKey!] =
                                              newPosition;
                                        }

                                        if (!_isPaused) {
                                          await _audioPlayer.play();
                                        }
                                      },
                                    ),


                                    Text(
                                      "${_formatDuration(
                                          _position)} / ${_formatDuration(
                                          _duration)}",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavAudioSource extends StreamAudioSource {
  final Uint8List bytes;

  _WavAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;

    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}