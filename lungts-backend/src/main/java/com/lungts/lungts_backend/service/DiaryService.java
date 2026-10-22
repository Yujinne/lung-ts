package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.DiaryRequest;
import com.lungts.lungts_backend.entity.Diary;
import com.lungts.lungts_backend.entity.DiarySymptom;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.repository.DiaryRepository;
import com.lungts.lungts_backend.repository.DiarySymptomRepository;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.lungts.lungts_backend.dto.DiaryResponse;
import java.util.List;
import com.lungts.lungts_backend.dto.SymptomStatisticsResponse;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.time.LocalDate;
import java.time.DayOfWeek;


@Service
@RequiredArgsConstructor
public class DiaryService {

    private final DiaryRepository diaryRepository;
    private final DiarySymptomRepository diarySymptomRepository;
    private final UserRepository userRepository;

    @Transactional
    public void saveDiary(String email, DiaryRequest request) {

        // 1. JWT에서 얻은 이메일로 현재 사용자 찾기
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        // 2. 일기 본문 저장
        Diary diary = Diary.builder()
                .user(user)
                .occurredAt(request.getOccurredAt())
                .memo(request.getMemo())
                .build();

        diaryRepository.save(diary);

        // 3. 선택한 증상들을 각각 저장
        for (String symptom : request.getSymptoms()) {

            DiarySymptom diarySymptom = DiarySymptom.builder()
                    .diary(diary)
                    .symptom(symptom)
                    .build();

            diarySymptomRepository.save(diarySymptom);
        }
    }

    @Transactional(readOnly = true)
    public List<DiaryResponse> getDiaries(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        return diaryRepository
                .findByUserOrderByOccurredAtDesc(user)
                .stream()
                .map(diary -> {

                    List<String> symptoms =
                            diarySymptomRepository
                                    .findByDiary(diary)
                                    .stream()
                                    .map(DiarySymptom::getSymptom)
                                    .toList();

                    return new DiaryResponse(
                            diary,
                            symptoms
                    );
                })
                .toList();
    }

    // 일기 수정 로직
    @Transactional
    public void updateDiary(
            String email,
            Long diaryId,
            DiaryRequest request
    ) {
        // 1. 현재 로그인 사용자 찾기
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        // 2. 수정할 일기 찾기
        Diary diary = diaryRepository.findById(diaryId)
                .orElseThrow(() ->
                        new IllegalArgumentException("일기를 찾을 수 없습니다.")
                );

        // 3. 본인 일기인지 확인
        if (!diary.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("본인의 일기만 수정할 수 있습니다.");
        }

        // 4. 날짜/시간과 메모 수정
        diary.update(
                request.getOccurredAt(),
                request.getMemo()
        );

        // 5. 기존 증상 삭제
        diarySymptomRepository.deleteByDiary(diary);

        // 6. 새로 선택한 증상 저장
        for (String symptom : request.getSymptoms()) {

            DiarySymptom diarySymptom = DiarySymptom.builder()
                    .diary(diary)
                    .symptom(symptom)
                    .build();

            diarySymptomRepository.save(diarySymptom);
        }
    }

    //일기 삭제 로직
    @Transactional
    public void deleteDiary(String email, Long diaryId) {

        // 1. 현재 로그인 사용자 찾기
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        // 2. 삭제할 일기 찾기
        Diary diary = diaryRepository.findById(diaryId)
                .orElseThrow(() ->
                        new IllegalArgumentException("일기를 찾을 수 없습니다.")
                );

        // 3. 본인의 일기인지 확인
        if (!diary.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("본인의 일기만 삭제할 수 있습니다.");
        }

        // 4. 일기에 연결된 증상 먼저 삭제
        diarySymptomRepository.deleteByDiary(diary);

        // 5. 일기 삭제
        diaryRepository.delete(diary);
    }

    @Transactional(readOnly = true)
    public SymptomStatisticsResponse getSymptomStatistics(
            String email,
            int year,
            int month
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        LocalDateTime start = LocalDateTime.of(year, month, 1, 0, 0);
        LocalDateTime end = start.plusMonths(1);

        return calculateSymptomStatistics(user, start, end);
    }

    // 일별 증상 통계
    @Transactional(readOnly = true)
    public SymptomStatisticsResponse getDailySymptomStatistics(
            String email,
            LocalDate date
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = start.plusDays(1);

        return calculateSymptomStatistics(user, start, end);
    }

    // 주별 증상 통계 (월요일 ~ 일요일)
    @Transactional(readOnly = true)
    public SymptomStatisticsResponse getWeeklySymptomStatistics(
            String email,
            LocalDate date
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        LocalDate monday = date.with(DayOfWeek.MONDAY);

        LocalDateTime start = monday.atStartOfDay();
        LocalDateTime end = start.plusDays(7);

        return calculateSymptomStatistics(user, start, end);
    }

    private SymptomStatisticsResponse calculateSymptomStatistics(
            User user,
            LocalDateTime start,
            LocalDateTime end
    ) {
        List<Diary> diaries =
                diaryRepository.findByUserOrderByOccurredAtDesc(user)
                        .stream()
                        .filter(diary ->
                                !diary.getOccurredAt().isBefore(start)
                                        && diary.getOccurredAt().isBefore(end))
                        .toList();

        Map<String, Integer> symptomCounts = new HashMap<>();

        Map<String, Map<String, Integer>> symptomTimeData =
                new LinkedHashMap<>();

        // 날짜별 증상 횟수
        Map<String, Map<String, Integer>> symptomDateData =
                new LinkedHashMap<>();

        symptomTimeData.put("새벽", new HashMap<>());
        symptomTimeData.put("오전", new HashMap<>());
        symptomTimeData.put("오후", new HashMap<>());
        symptomTimeData.put("저녁", new HashMap<>());

        for (Diary diary : diaries) {
            List<DiarySymptom> symptoms =
                    diarySymptomRepository.findByDiary(diary);

            // 일기가 작성된 증상 발생 날짜
            String dateKey = diary.getOccurredAt().toLocalDate().toString();

            Map<String, Integer> dateCounts =
                    symptomDateData.computeIfAbsent(
                            dateKey,
                            key -> new HashMap<>()
                    );

            int hour = diary.getOccurredAt().getHour();

            String timeSlot;

            if (hour < 6) {
                timeSlot = "새벽";
            } else if (hour < 12) {
                timeSlot = "오전";
            } else if (hour < 18) {
                timeSlot = "오후";
            } else {
                timeSlot = "저녁";
            }

            for (DiarySymptom diarySymptom : symptoms) {
                String symptom = diarySymptom.getSymptom();

                // 날짜별 증상 발생 횟수
                dateCounts.put(
                        symptom,
                        dateCounts.getOrDefault(symptom, 0) + 1
                );

                symptomCounts.put(
                        symptom,
                        symptomCounts.getOrDefault(symptom, 0) + 1
                );

                Map<String, Integer> timeCounts =
                        symptomTimeData.get(timeSlot);

                timeCounts.put(
                        symptom,
                        timeCounts.getOrDefault(symptom, 0) + 1
                );
            }
        }

        return new SymptomStatisticsResponse(
                symptomCounts,
                symptomTimeData,
                symptomDateData
        );
    }
}