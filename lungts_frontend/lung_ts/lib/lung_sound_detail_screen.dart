import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'dart:convert';

class LungSoundDetailScreen extends StatefulWidget {
  final int resultId;
  final String recordedTime;
  final List<Map<String, dynamic>> records;

  const LungSoundDetailScreen({
    super.key,
    required this.resultId,
    required this.recordedTime,
    required this.records,
  });

  @override
  State<LungSoundDetailScreen> createState() =>
      _LungSoundDetailScreenState();
}

class _LungSoundDetailScreenState
    extends State<LungSoundDetailScreen>
    with SingleTickerProviderStateMixin {

  late int selectedResultId;
  Uint8List? audioBytes;
  bool isLoadingAudio = false;
  String? audioError;

  // WAV 재생 관련
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;
  late final Ticker _waveformTicker;

  // 파형을 직접 조작하고 있는지
  bool _isWaveformDragging = false;

  // WAV 파형 데이터
  List<double> audioSamples = [];
  int audioSampleRate = 44100;

  // 10ms 간격으로 계산한 RMS 파형 데이터
  List<double> waveformRms = [];

  // 폐소리 측정 상세 정보
  Map<String, dynamic>? lungSoundDetail;

  // 복약 정보 수정 상태
  bool _isMedicationEditing = false;
  String _selectedMedicationStatus = 'BEFORE';
  List<int> _selectedMedicationRecordIds = [];
  bool _isMedicationSaving = false;

  List<Map<String, dynamic>> _availableMedicationRecords = [];
  bool _isMedicationLoading = false;
  String? _medicationError;

  // 폐소리 측정 메모
  final TextEditingController _memoController = TextEditingController();
  bool _isMemoSaving = false;

  bool _isMemoEditing = false;
  String _originalMemo = '';

  @override
  void initState() {
    super.initState();

    _waveformTicker = createTicker((elapsed) {
      if (!mounted || !_audioPlayer.playing) return;

      setState(() {
        audioPosition = _audioPlayer.position;
      });
    });

    _waveformTicker.start();

    selectedResultId = widget.resultId;
    _loadAudio();

    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;

      setState(() {
        audioPosition = position;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;

      setState(() {
        audioDuration = duration ?? Duration.zero;
      });
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing &&
            state.processingState != ProcessingState.completed;
      });
    });
  }

  @override
  void dispose() {
    _waveformTicker.dispose();
    _audioPlayer.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadLungSoundDetail() async {
    final resultId = selectedResultId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/api/lung-sounds/$resultId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted || selectedResultId != resultId) return;

      if (response.statusCode == 200) {
        final detail = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;

        setState(() {
          lungSoundDetail = detail;

          // 메모
          _originalMemo = detail['memo']?.toString() ?? '';
          _memoController.text = _originalMemo;
          _isMemoEditing = false;

          // 복약 정보
          _selectedMedicationStatus =
              detail['medicationStatus']?.toString() ?? 'BEFORE';

          _selectedMedicationRecordIds =
              ((detail['medicationRecordIds'] as List?) ?? [])
                  .map((id) => (id as num).toInt())
                  .toList();

          _isMedicationEditing = false;
        });
      } else {
        debugPrint('폐소리 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('폐소리 상세 조회 오류: $e');
    }
  }

  Future<void> _loadAvailableMedicationRecords() async {
    final resultId = selectedResultId;
    final detail = lungSoundDetail;
    if (detail == null) return;

    final recordedAtText = detail['recordedAt']?.toString();
    final recordedAt = DateTime.tryParse(recordedAtText ?? '');

    if (recordedAt == null) {
      setState(() {
        _medicationError = '측정 시간을 확인할 수 없습니다.';
      });
      return;
    }

    setState(() {
      _isMedicationLoading = true;
      _medicationError = null;
      _availableMedicationRecords = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final date =
          '${recordedAt.year.toString().padLeft(4, '0')}-'
          '${recordedAt.month.toString().padLeft(2, '0')}-'
          '${recordedAt.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/api/medication-records?date=$date',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('복약 기록 조회 실패: ${response.statusCode}');
      }

      final List<dynamic> data =
      jsonDecode(utf8.decode(response.bodyBytes));

      final records = data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((record) {
        final takenAt = DateTime.tryParse(
          record['takenAt']?.toString() ?? '',
        );

        return takenAt != null && !takenAt.isAfter(recordedAt);
      })
          .toList();

      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        _availableMedicationRecords = records;
      });
    } catch (e) {
      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        _medicationError = e.toString();
      });
    } finally {
      if (mounted && selectedResultId == resultId) {
        setState(() {
          _isMedicationLoading = false;
        });
      }
    }
  }


  Future<void> _saveMemo() async {
    final resultId = selectedResultId;

    if (_isMemoSaving) return;

    final memo = _memoController.text;

    if (memo.length > 200) {
      debugPrint('메모는 200자 이내로 작성해주세요.');
      return;
    }

    setState(() {
      _isMemoSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        debugPrint('로그인 정보가 없습니다.');
        return;
      }

      final response = await http.patch(
        Uri.parse('http://localhost:8080/api/lung-sounds/$resultId/memo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'memo': memo,
        }),
      );

      if (!mounted || selectedResultId != resultId) return;

      if (response.statusCode == 200) {
        final detail = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;

        setState(() {
          lungSoundDetail = detail;

          _originalMemo = detail['memo']?.toString() ?? memo;
          _memoController.text = _originalMemo;

          _isMemoEditing = false;
        });

        debugPrint('폐소리 메모 저장 완료');
      } else {
        debugPrint('폐소리 메모 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('폐소리 메모 저장 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMemoSaving = false;
        });
      }
    }
  }

  Future<void> _saveMedication() async {
    if (_isMedicationSaving) return;

    if (_selectedMedicationStatus == 'AFTER' &&
        _selectedMedicationRecordIds.isEmpty) {
      setState(() {
        _medicationError = '복약 기록을 하나 이상 선택해주세요.';
      });
      return;
    }

    final resultId = selectedResultId;

    setState(() {
      _isMedicationSaving = true;
      _medicationError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.patch(
        Uri.parse(
          'http://localhost:8080/api/lung-sounds/$resultId/medication',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'medicationStatus': _selectedMedicationStatus,
          'medicationRecordIds':
          _selectedMedicationStatus == 'AFTER'
              ? _selectedMedicationRecordIds
              : <int>[],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('복약 정보 저장 실패: ${response.statusCode}');
      }

      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        _isMedicationEditing = false;
      });

      await _loadLungSoundDetail();
    } catch (e) {
      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        _medicationError = e.toString();
      });
    } finally {
      if (mounted && selectedResultId == resultId) {
        setState(() {
          _isMedicationSaving = false;
        });
      }
    }
  }

  Future<void> _loadAudio() async {
    await _audioPlayer.stop();
    final resultId = selectedResultId;

    setState(() {
      lungSoundDetail = null;
      _memoController.clear();
    });

    _loadLungSoundDetail();

    setState(() {
      isLoadingAudio = true;
      audioError = null;
      audioBytes = null;

      isPlaying = false;
      audioDuration = Duration.zero;
      audioPosition = Duration.zero;

      // 다른 WAV 선택 시 이전 파일 파형 데이터 삭제
      audioSamples = [];
      waveformRms = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/api/lung-sounds/$resultId/audio',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('WAV 파일 조회 실패: ${response.statusCode}');
      }

      if (!mounted || selectedResultId != resultId) return;

      _inspectWavFormat(response.bodyBytes);

      _extractAudioSamples(response.bodyBytes);

      waveformRms = _calculateWaveformRms(
        audioSamples,
        audioSampleRate,
      );

      await _audioPlayer.setAudioSource(
        _WavAudioSource(response.bodyBytes),
        initialPosition: Duration.zero,
      );

      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        audioBytes = response.bodyBytes;
        audioPosition = Duration.zero;
      });
    } catch (e) {
      if (!mounted || selectedResultId != resultId) return;

      setState(() {
        audioError = e.toString();
      });
    } finally {
      if (mounted && selectedResultId == resultId) {
        setState(() {
          isLoadingAudio = false;
        });
      }
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (audioBytes == null || isLoadingAudio) return;

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      // 아직 오디오가 설정되지 않았다면 WAV 데이터 연결
      if (_audioPlayer.audioSource == null) {
        await _audioPlayer.setAudioSource(
          _WavAudioSource(audioBytes!),
        );
      }

      // 재생이 끝난 파일은 처음부터 다시 재생
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }

      await _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        audioError = '오디오 재생 실패: $e';
      });
    }
  }

  String _formatAudioDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  void _inspectWavFormat(Uint8List bytes) {
    if (bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(bytes.sublist(8, 12)) != 'WAVE') {
      debugPrint('지원하지 않는 WAV 파일입니다.');
      return;
    }

    final data = ByteData.sublistView(bytes);
    int offset = 12;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(
        bytes.sublist(offset, offset + 4),
      );
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkEnd = offset + 8 + chunkSize;

      if (chunkEnd > bytes.length) break;

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        final audioFormat = data.getUint16(offset + 8, Endian.little);
        final channels = data.getUint16(offset + 10, Endian.little);
        final sampleRate = data.getUint32(offset + 12, Endian.little);
        final bitsPerSample = data.getUint16(offset + 22, Endian.little);

        debugPrint('===== WAV 정보 =====');
        debugPrint('Audio Format: $audioFormat');
        debugPrint('Channels: $channels');
        debugPrint('Sample Rate: $sampleRate Hz');
        debugPrint('Bits Per Sample: $bitsPerSample');
        return;
      }

      offset = chunkEnd + (chunkSize.isOdd ? 1 : 0);
    }

    debugPrint('WAV fmt 청크를 찾지 못했습니다.');
  }

  void _extractAudioSamples(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    int offset = 12;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(
        bytes.sublist(offset, offset + 4),
      );

      final chunkSize = data.getUint32(
        offset + 4,
        Endian.little,
      );

      final dataStart = offset + 8;
      final dataEnd = dataStart + chunkSize;

      if (dataEnd > bytes.length) break;

      if (chunkId == 'data') {
        final samples = <double>[];

        // 16bit PCM / 모노
        for (int i = dataStart; i + 1 < dataEnd; i += 2) {
          final sample = data.getInt16(i, Endian.little);

          // -32768 ~ 32767 → -1.0 ~ 1.0
          samples.add(sample / 32768.0);
        }

        audioSamples = samples;

        debugPrint('PCM 샘플 추출 완료: ${samples.length}개');
        debugPrint(
          '음성 길이: ${(samples.length / audioSampleRate).toStringAsFixed(2)}초',
        );

        return;
      }

      offset = dataEnd + (chunkSize.isOdd ? 1 : 0);
    }

    debugPrint('WAV data 청크를 찾지 못했습니다.');
  }

  List<double> _calculateWaveformRms(
      List<double> samples,
      int sampleRate,
      ) {
    if (samples.isEmpty || sampleRate <= 0) {
      return [];
    }

    // 10ms마다 소리 크기 계산
    final samplesPerFrame = (sampleRate * 0.01).round();
    final result = <double>[];

    for (int start = 0;
    start < samples.length;
    start += samplesPerFrame) {
      final end = math.min(
        start + samplesPerFrame,
        samples.length,
      );

      double sumSquares = 0;

      for (int i = start; i < end; i++) {
        final sample = samples[i];
        sumSquares += sample * sample;
      }

      final rms = math.sqrt(
        sumSquares / (end - start),
      );

      result.add(rms);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '폐소리 상세 기록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedResultId,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF3678C8),
                  ),
                  items: widget.records.map((record) {
                    final id = (record['id'] as num).toInt();
                    final time = record['time'] as String;

                    final formattedTime =
                        '${time.substring(0, 2)}:${time.substring(2)}';

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        '$formattedTime 측정 기록',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null || value == selectedResultId) return;

                    setState(() {
                      selectedResultId = value;
                    });

                    _loadAudio();
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '폐소리 측정 상세 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingAudio)
                    const Center(child: CircularProgressIndicator())
                  else if (audioError != null)
                    Text(
                      audioError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (audioBytes != null)
                      Column(
                        children: [
                          // 실시간 폐소리 파형
                          Container(
                            width: double.infinity,
                            height: 150,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                void seekWaveform(double deltaX) {
                                  if (audioDuration <= Duration.zero) return;

                                  // 파형에 표시되는 전체 구간은 3초
                                  const windowSeconds = 3.0;

                                  final deltaSeconds =
                                      deltaX / constraints.maxWidth * windowSeconds;

                                  final newPosition =
                                      audioPosition.inMicroseconds / 1000000.0 - deltaSeconds;

                                  final clampedSeconds = newPosition.clamp(
                                    0.0,
                                    audioDuration.inMicroseconds / 1000000.0,
                                  );

                                  final target = Duration(
                                    microseconds: (clampedSeconds * 1000000).round(),
                                  );

                                  setState(() {
                                    audioPosition = target;
                                  });

                                  _audioPlayer.seek(target);
                                }

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,

                                  onHorizontalDragStart: (_) {
                                    setState(() {
                                      _isWaveformDragging = true;
                                    });
                                  },

                                  onHorizontalDragUpdate: (details) {
                                    seekWaveform(details.delta.dx);
                                  },

                                  onHorizontalDragEnd: (_) {
                                    setState(() {
                                      _isWaveformDragging = false;
                                    });
                                  },

                                  onHorizontalDragCancel: () {
                                    setState(() {
                                      _isWaveformDragging = false;
                                    });
                                  },

                                  child: ClipRect(
                                    child: CustomPaint(
                                      painter: LungWaveformPainter(
                                        rmsValues: waveformRms,
                                        position: audioPosition,
                                        showTime: _isWaveformDragging,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _toggleAudioPlayback,
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 42,
                                  color: const Color(0xFF3678C8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '폐소리 전체 재생',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Slider(
                            min: 0,
                            max: audioDuration.inMilliseconds > 0
                                ? audioDuration.inMilliseconds.toDouble()
                                : 1,
                            value: audioPosition.inMilliseconds
                                .toDouble()
                                .clamp(
                              0,
                              audioDuration.inMilliseconds > 0
                                  ? audioDuration.inMilliseconds.toDouble()
                                  : 1,
                            ),
                            activeColor: const Color(0xFF3678C8),
                            onChanged: audioDuration > Duration.zero
                                ? (value) {
                              _audioPlayer.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            }
                                : null,
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatAudioDuration(audioPosition)),
                              Text(_formatAudioDuration(audioDuration)),
                            ],
                          ),
                        ],
                      ),
                ],

              ),
            ),
            const SizedBox(height: 16),

            if (lungSoundDetail != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '복약 정보',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!_isMedicationEditing)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF3678C8),
                              size: 21,
                            ),
                            onPressed: () {
                              setState(() {
                                _isMedicationEditing = true;
                              });

                              _loadAvailableMedicationRecords();
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_isMedicationEditing) ...[
                      const Text(
                        '측정 상태',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          for (final status in ['BEFORE', 'AFTER']) ...[
                            if (status == 'AFTER') const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _selectedMedicationStatus = status;
                                    _medicationError = null;

                                    if (status == 'BEFORE') {
                                      _selectedMedicationRecordIds.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedMedicationStatus == status
                                        ? const Color(0xFFEAF2FF)
                                        : const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedMedicationStatus == status
                                          ? const Color(0xFF3977E8)
                                          : const Color(0xFFE5E7EB),
                                      width: _selectedMedicationStatus == status ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selectedMedicationStatus == status
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        size: 19,
                                        color: _selectedMedicationStatus == status
                                            ? const Color(0xFF3977E8)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        status == 'BEFORE' ? '복약 전' : '복약 후',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedMedicationStatus == status
                                              ? const Color(0xFF3977E8)
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (_selectedMedicationStatus == 'AFTER') ...[
                        const SizedBox(height: 12),
                        const Text(
                          '연결할 복약 기록',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isMedicationLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else if (_availableMedicationRecords.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.medication_outlined,
                                    size: 24,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '연결 가능한 복약 기록이 없습니다.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '측정 시간 이전에 등록한 복약 기록이 표시됩니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._availableMedicationRecords.map((record) {
                              final id = (record['id'] as num).toInt();
                              final name = record['medicineName']?.toString() ?? '약 이름 없음';
                              final dose = record['dose']?.toString() ?? '';
                              final unit = record['doseUnit']?.toString() ?? '';
                              final takenAt = record['takenAt']?.toString() ?? '';
                              final time = takenAt.length >= 16
                                  ? takenAt.substring(11, 16)
                                  : '';

                              return CheckboxListTile(
                                value: _selectedMedicationRecordIds.contains(id),
                                activeColor: const Color(0xFF3678C8),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '$dose$unit · $time',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      if (!_selectedMedicationRecordIds.contains(id)) {
                                        _selectedMedicationRecordIds.add(id);
                                      }
                                    } else {
                                      _selectedMedicationRecordIds.remove(id);
                                    }
                                  });
                                },
                              );
                            }),
                      ],

                      const SizedBox(height: 16),

                      if (_medicationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _medicationError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isMedicationSaving
                                  ? null
                                  : () {
                                setState(() {
                                  _isMedicationEditing = false;
                                  _medicationError = null;
                                });
                                _loadLungSoundDetail();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
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
                              onPressed: _isMedicationSaving || _isMedicationLoading
                                  ? null
                                  : _saveMedication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3977E8),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFBFCFEF),
                                minimumSize: const Size(0, 44),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isMedicationSaving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text('저장'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Text(
                            '측정 상태',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            lungSoundDetail!['medicationStatus'] == 'AFTER'
                                ? '복약 후'
                                : '복약 전',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3678C8),
                            ),
                          ),
                        ],
                      ),

                      if (lungSoundDetail!['medicationStatus'] == 'AFTER') ...[
                        const Divider(),
                        const SizedBox(height: 8),

                        ...((lungSoundDetail!['medications'] as List?) ?? [])
                            .map((medication) {
                          final name = medication['medicineName'] ?? '약 이름 없음';
                          final dose = medication['dose'];
                          final unit = medication['doseUnit'] ?? '';
                          final takenAt = medication['takenAt']?.toString() ?? '';
                          final time = takenAt.length >= 16
                              ? takenAt.substring(11, 16)
                              : '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medication_outlined,
                                  color: Color(0xFF3678C8),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$name · $dose$unit',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],

                    const SizedBox(height: 12),

                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 폐소리 측정 메모 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 수정 아이콘
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF3977E8),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (!_isMemoEditing)
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF3977E8),
                            size: 21,
                          ),
                          onPressed: lungSoundDetail == null
                              ? null
                              : () {
                            setState(() {
                              _isMemoEditing = true;
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 메모 입력 영역
                  TextField(
                    controller: _memoController,
                    readOnly: !_isMemoEditing,
                    maxLines: 4,
                    maxLength: _isMemoEditing ? 200 : null,
                    showCursor: _isMemoEditing,
                    enableInteractiveSelection: _isMemoEditing,
                    decoration: InputDecoration(
                      hintText: _isMemoEditing
                          ? '측정 당시의 증상이나 특이사항을 기록해 주세요.'
                          : '작성된 메모가 없습니다.',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FA),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // 수정 모드에서만 버튼 표시
                  if (_isMemoEditing) ...[
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isMemoSaving
                                ? null
                                : () {
                              setState(() {
                                _memoController.text = _originalMemo;
                                _isMemoEditing = false;
                              });

                              FocusScope.of(context).unfocus();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
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
                            onPressed: _isMemoSaving ? null : _saveMemo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3977E8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isMemoSaving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

class LungWaveformPainter extends CustomPainter {
  final List<double> rmsValues;
  final Duration position;
  final bool showTime;

  LungWaveformPainter({
    required this.rmsValues,
    required this.position,
    required this.showTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3678C8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final baseline = size.height * 0.8;

    if (rmsValues.isEmpty) {
      canvas.drawLine(
        Offset(0, baseline),
        Offset(size.width, baseline),
        paint,
      );
      return;
    }

    // RMS 데이터는 10ms 간격으로 저장되어 있음
    const rmsInterval = 0.01;

// 화면에 표시할 전체 시간: 3초
    const windowSeconds = 3.0;
    const pointCount = 301;

    final currentTime = position.inMicroseconds / 1000000.0;
    final halfWindow = windowSeconds / 2;

    double previousAmplitude = 0;

    for (int x = 0; x < pointCount; x++) {
      // 가운데가 현재 재생 시점
      final time = currentTime - halfWindow +
          x * windowSeconds / (pointCount - 1);

      final index = (time / rmsInterval).floor();

      double rms = 0;

      if (index >= 0 && index < rmsValues.length) {
        rms = rmsValues[index];
      }

      // 실제 소리 크기 확대
      final rawAmplitude = (rms * 8).clamp(0.0, 1.0);

      // 인접한 점의 높이를 부드럽게 연결
      final amplitude =
          previousAmplitude * 0.65 + rawAmplitude * 0.35;

      previousAmplitude = amplitude;

      final dx = x * size.width / (pointCount - 1);
      final dy = baseline - amplitude * size.height * 0.7;

      if (x == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(path, paint);

    // 현재 재생 위치 표시선
    final cursorPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      cursorPaint,
    );

    if (showTime) {
      final totalMilliseconds = position.inMilliseconds;

      final minutes =
      (totalMilliseconds ~/ 60000).toString().padLeft(2, '0');

      final seconds =
      ((totalMilliseconds ~/ 1000) % 60).toString().padLeft(2, '0');

      final centiseconds =
      ((totalMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

      final timeText = '$minutes:$seconds.$centiseconds';

      final textPainter = TextPainter(
        text: TextSpan(
          text: timeText,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout();

      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LungWaveformPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.rmsValues != rmsValues ||
        oldDelegate.showTime != showTime;
  }
}