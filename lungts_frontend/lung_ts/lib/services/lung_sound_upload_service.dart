import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'lung_sound_sample_service.dart';

class LungSoundUploadService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<Map<String, dynamic>> upload({
    required DateTime recordedAt,
    required String medicationStatus,
    List<int>? medicationRecordIds,
  }) async {
    if (medicationStatus != 'BEFORE' &&
        medicationStatus != 'AFTER') {
      throw Exception('올바르지 않은 복약 상태입니다.');
    }

    if (medicationStatus == 'AFTER' &&
        (medicationRecordIds == null || medicationRecordIds.isEmpty)) {
      throw Exception('복약 기록을 선택해주세요.');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    // 1. 다음 테스트용 WAV 파일 가져오기
    final samplePath =
    await LungSoundSampleService.getNextSamplePath();

    final byteData = await rootBundle.load(samplePath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    // 2. multipart 요청 생성
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/lung-sounds/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['recordedAt'] =
        recordedAt.toIso8601String().split('.').first;

    request.fields['medicationStatus'] = medicationStatus;

    if (medicationStatus == 'AFTER') {
      for (final id in medicationRecordIds!) {
        request.files.add(
          http.MultipartFile.fromString(
            'medicationRecordIds',
            id.toString(),
          ),
        );
      }
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: samplePath.split('/').last,
      ),
    );

    // 3. 서버에 업로드
    final streamedResponse = await request.send();
    final response =
    await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        '폐소리 업로드 실패 (${response.statusCode}): '
            '${utf8.decode(response.bodyBytes)}',
      );
    }

    final result = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;

    // 4. 서버 저장 성공 후에만 다음 WAV 파일로 이동
    await LungSoundSampleService.moveToNextSample();

    return result;
  }
}