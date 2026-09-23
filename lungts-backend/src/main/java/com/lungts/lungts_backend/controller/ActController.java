package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.ActResultRequest;
import com.lungts.lungts_backend.dto.ActResultResponse;
import com.lungts.lungts_backend.service.ActService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/act")
@RequiredArgsConstructor
public class ActController {

    private final ActService actService;

    @PostMapping
    public ResponseEntity<String> saveResult(
            Authentication authentication,
            @RequestBody ActResultRequest request
    ) {
        String email = authentication.getName();

        actService.saveResult(email, request);

        return ResponseEntity.ok("ACT 결과 저장 성공");
    }

    @GetMapping
    public ResponseEntity<List<ActResultResponse>> getResults(
            Authentication authentication
    ) {
        String email = authentication.getName();

        List<ActResultResponse> results =
                actService.getResults(email);

        return ResponseEntity.ok(results);
    }
}