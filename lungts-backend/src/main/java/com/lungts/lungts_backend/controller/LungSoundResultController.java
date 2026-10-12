package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.LungSoundResultRequest;
import com.lungts.lungts_backend.dto.LungSoundResultResponse;
import com.lungts.lungts_backend.service.LungSoundResultService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/lung-sounds")
@RequiredArgsConstructor
public class LungSoundResultController {

    private final LungSoundResultService lungSoundResultService;

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
}