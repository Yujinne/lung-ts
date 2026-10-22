package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.DiaryRequest;
import com.lungts.lungts_backend.service.DiaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.lungts.lungts_backend.dto.DiaryResponse;
import com.lungts.lungts_backend.dto.SymptomStatisticsResponse;
import org.springframework.web.bind.annotation.RequestParam;
import java.util.List;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/diaries")
@RequiredArgsConstructor
public class DiaryController {

    private final DiaryService diaryService;

    @PostMapping
    public ResponseEntity<String> saveDiary(
            Authentication authentication,
            @RequestBody DiaryRequest request
    ) {
        String email = authentication.getName();

        diaryService.saveDiary(email, request);

        return ResponseEntity.ok("일기 저장 성공");
    }

    @GetMapping
    public ResponseEntity<List<DiaryResponse>> getDiaries(
            Authentication authentication
    ) {
        String email = authentication.getName();

        List<DiaryResponse> diaries =
                diaryService.getDiaries(email);

        return ResponseEntity.ok(diaries);
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> updateDiary(
            Authentication authentication,
            @PathVariable Long id,
            @RequestBody DiaryRequest request
    ) {
        String email = authentication.getName();

        diaryService.updateDiary(
                email,
                id,
                request
        );

        return ResponseEntity.ok("일기 수정 성공");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteDiary(
            Authentication authentication,
            @PathVariable Long id
    ) {
        String email = authentication.getName();

        diaryService.deleteDiary(email, id);

        return ResponseEntity.ok("일기 삭제 성공");
    }

    //통계 조회 API
    @GetMapping("/statistics")
    public ResponseEntity<SymptomStatisticsResponse> getSymptomStatistics(
            Authentication authentication,
            @RequestParam int year,
            @RequestParam int month
    ) {
        String email = authentication.getName();

        SymptomStatisticsResponse statistics =
                diaryService.getSymptomStatistics(email, year, month);

        return ResponseEntity.ok(statistics);
    }

    // 일별 증상 통계 조회
    @GetMapping("/statistics/daily")
    public ResponseEntity<SymptomStatisticsResponse> getDailySymptomStatistics(
            Authentication authentication,
            @RequestParam LocalDate date
    ) {
        String email = authentication.getName();

        SymptomStatisticsResponse statistics =
                diaryService.getDailySymptomStatistics(email, date);

        return ResponseEntity.ok(statistics);
    }

    // 주별 증상 통계 조회
    @GetMapping("/statistics/weekly")
    public ResponseEntity<SymptomStatisticsResponse> getWeeklySymptomStatistics(
            Authentication authentication,
            @RequestParam LocalDate date
    ) {
        String email = authentication.getName();

        SymptomStatisticsResponse statistics =
                diaryService.getWeeklySymptomStatistics(email, date);

        return ResponseEntity.ok(statistics);
    }

}