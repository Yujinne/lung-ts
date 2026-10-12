// 음성 측정 기록
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';


class LungLogScreen extends StatefulWidget {
  @override
  State<LungLogScreen> createState() => _LungLogScreenState();

}

class _LungLogScreenState extends State<LungLogScreen> {
  Set<DateTime> measuredDates = {};
  Map<String, List<String>> fileTimes = {};

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

  List<String> getTimesForDay(DateTime day) {
    final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
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

      final Map<String, List<String>> newFileTimes = {};
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
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        final time =
            '${recordedAt.hour.toString().padLeft(2, '0')}'
            '${recordedAt.minute.toString().padLeft(2, '0')}';

        newFileTimes[dateKey] =
        (newFileTimes[dateKey] ?? [])..add(time);
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
    final selectedKey = "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: Text('음성측정기록')),
      body: Column(
        children: [
          // ✅ 이전/다음 월 이동 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: _goToPreviousMonth, child: Text("이전")),
                Text("${focusedDay.year}년 ${focusedDay.month.toString().padLeft(2, '0')}월",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _goToNextMonth, child: Text("다음")),
              ],
            ),
          ),

          TableCalendar(
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
                bool isMeasured = measuredDates.any((d) => isSameDay(d, day));
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isMeasured ? Colors.amberAccent.shade100 : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${day.day}'),
                );
              },
            ),
          ),

          Divider(),

          if (times.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('선택한 날짜에 저장된 음성이 없습니다.'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: times.length,
                itemBuilder: (context, index) {
                  final time = times[index];
                  final formatted = "${time.substring(0, 2)}:${time.substring(2)}";
                  final isPlaying = _playingKey == time;
                  final isSelected = _playingKey == time;
                  final isActuallyPlaying = isSelected && _audioPlayer.playing;


                  // 가정: 저장된 경로는 이와 같은 형식임. 필요 시 수정
                  final datePath = selectedKey.replaceAll('-', '.'); // "2025.05.14"
                  //final voiceUrl = "https://your_server_or_storage/${user.uid}/$datePath/$time.wav";

                  final voiceUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

                  return Column(
                    children: [
                      ListTile(
                        title: Text("$formatted 측정 음성"),
                        trailing: IconButton(

                          icon: Icon(isActuallyPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () async {
                              if (isActuallyPlaying) {
                                // 재생 중 → 일시정지
                                await _audioPlayer.pause();
                                // 정확한 위치를 스트림에서 한 번 가져옴
                                final currentPos = await _audioPlayer.positionStream.first;

                                setState(() {
                                  _isPaused = true;
                                  _pausedPositions[_playingKey!] = currentPos;
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
                                  _pausedPositions.removeWhere((key, _) => key != time);

                                  await _audioPlayer.setUrl(voiceUrl);

                                  final duration = await _audioPlayer.durationFuture;
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Slider(
                                min: 0,
                                max: _duration.inSeconds.toDouble(),
                                value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                                onChanged: (value) {
                                  setState(() {
                                    _position = Duration(seconds: value.toInt());
                                  });
                                },
                                onChangeEnd: (value) async {
                                  final newPosition = Duration(seconds: value.toInt());
                                  await _audioPlayer.seek(newPosition);

                                  if (_playingKey != null) {
                                    _pausedPositions[_playingKey!] = newPosition;
                                  }

                                  if (!_isPaused) {
                                    await _audioPlayer.play();
                                  }
                                },
                              ),


                              Text(
                                "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            )

        ],
      ),
    );
  }
}
