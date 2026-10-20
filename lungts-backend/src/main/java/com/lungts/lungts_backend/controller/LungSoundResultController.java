package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.LungSoundResultRequest;
import com.lungts.lungts_backend.dto.LungSoundResultResponse;
import com.lungts.lungts_backend.service.LungSoundResultService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.lungts.lungts_backend.entity.MedicationStatus;
import com.lungts.lungts_backend.service.LungSoundFileService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;

import java.util.List;

@RestController
@RequestMapping("/api/lung-sounds")
@RequiredArgsConstructor
public class LungSoundResultController {

    private final LungSoundResultService lungSoundResultService;
    private final LungSoundFileService lungSoundFileService;

    // 측정 기록 저장
    @PostMapping
    public ResponseEntity<LungSoundResultResponse> create(
            Authentication authentication,
            @RequestBody LungSoundResultRequest request
    ) {
        String email = authentication.getName();

        return ResponseEntity.ok(
                lungSoundResultService.create(email, request)
        );
    }

    // 측정 기록 전체 조회
    @GetMapping
    public ResponseEntity<List<LungSoundResultResponse>> getAll(
            Authentication authentication
    ) {
        String email = authentication.getName();

        return ResponseEntity.ok(
                lungSoundResultService.getAll(email)
        );
    }

    // 측정 기록 삭제
    @DeleteMapping("/{resultId}")
    public ResponseEntity<Void> delete(
            Authentication authentication,
            @PathVariable Long resultId
    ) {
        String email = authentication.getName();

        lungSoundResultService.delete(email, resultId);

        return ResponseEntity.noContent().build();
    }

    // WAV 파일 업로드 + 폐소리 측정 기록 저장
    @PostMapping(
            value = "/upload",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<LungSoundResultResponse> upload(
            Authentication authentication,

            @RequestParam("file") MultipartFile file,

            @RequestParam("recordedAt")
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
            LocalDateTime recordedAt,

            @RequestParam("medicationStatus")
            MedicationStatus medicationStatus,

            @RequestParam(
                    value = "medicationRecordIds",
                    required = false
            )
            List<Long> medicationRecordIds
    ) throws IOException {

        String email = authentication.getName();

        // 1. WAV 파일 서버 저장
        String audioPath = lungSoundFileService.saveWavFile(file);

        // 2. 폐소리 기록 DB 저장
        return ResponseEntity.ok(
                lungSoundResultService.createWithFile(
                        email,
                        recordedAt,
                        audioPath,
                        medicationStatus,
                        medicationRecordIds
                )
        );
    }
}