import 'package:shared_preferences/shared_preferences.dart';

class LungSoundSampleService {
  static const int totalSamples = 61;
  static const String _key = 'next_lung_sound_sample';

  // 다음 사용할 WAV 파일 경로
  static Future<String> getNextSamplePath() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1;

    final fileName = 'sample_${index.toString().padLeft(3, '0')}.wav';

    return 'assets/audio/$fileName';
  }

  // 업로드 성공 후에만 다음 파일로 이동
  static Future<void> moveToNextSample() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1;

    final nextIndex = index >= totalSamples ? 1 : index + 1;

    await prefs.setInt(_key, nextIndex);
  }
}