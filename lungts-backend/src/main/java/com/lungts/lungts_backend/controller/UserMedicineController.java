package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.UserMedicineRequest;
import com.lungts.lungts_backend.dto.UserMedicineResponse;
import com.lungts.lungts_backend.service.UserMedicineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.lungts.lungts_backend.dto.UserMedicineBulkRequest;

import java.util.List;

@RestController
@RequestMapping("/api/user-medicines")
@RequiredArgsConstructor
public class UserMedicineController {

    private final UserMedicineService userMedicineService;

    // 내 약 등록
    @PostMapping
    public ResponseEntity<UserMedicineResponse> register(
            Authentication authentication,
            @RequestBody UserMedicineRequest request
    ) {
        UserMedicineResponse response =
                userMedicineService.register(
                        authentication.getName(),
                        request
                );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    // 내 약 목록 조회
    @GetMapping
    public ResponseEntity<List<UserMedicineResponse>> getMyMedicines(
            Authentication authentication
    ) {
        return ResponseEntity.ok(
                userMedicineService.getMyMedicines(
                        authentication.getName()
                )
        );
    }

    // 약 사용 중단
    @PatchMapping("/{medicineId}/deactivate")
    public ResponseEntity<Void> deactivate(
            Authentication authentication,
            @PathVariable Long medicineId
    ) {
        userMedicineService.deactivate(
                authentication.getName(),
                medicineId
        );

        return ResponseEntity.noContent().build();
    }

    @PostMapping("/bulk")
    public ResponseEntity<List<UserMedicineResponse>> registerBulk(
            Authentication authentication,
            @RequestBody UserMedicineBulkRequest request
    ) {
        List<UserMedicineResponse> responses =
                userMedicineService.registerBulk(
                        authentication.getName(),
                        request
                );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(responses);
    }
}