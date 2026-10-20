
package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.MedicationRecordRequest;
import com.lungts.lungts_backend.dto.MedicationRecordResponse;
import com.lungts.lungts_backend.service.MedicationRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/medication-records")
@RequiredArgsConstructor
public class MedicationRecordController {

    private final MedicationRecordService medicationRecordService;

    // 1. 복약 기록 등록
    @PostMapping
    public ResponseEntity<MedicationRecordResponse> create(
            Authentication authentication,
            @RequestBody MedicationRecordRequest request
    ) {
        MedicationRecordResponse response =
                medicationRecordService.create(
                        authentication.getName(),
                        request
                );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    // 2. 날짜별 복약 기록 조회
    @GetMapping
    public ResponseEntity<List<MedicationRecordResponse>> getByDate(
            Authentication authentication,
            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        return ResponseEntity.ok(
                medicationRecordService.getByDate(
                        authentication.getName(),
                        date
                )
        );
    }

    // 3. 복약 기록 수정
    @PutMapping("/{recordId}")
    public ResponseEntity<MedicationRecordResponse> update(
            Authentication authentication,
            @PathVariable Long recordId,
            @RequestBody MedicationRecordRequest request
    ) {
        return ResponseEntity.ok(
                medicationRecordService.update(
                        authentication.getName(),
                        recordId,
                        request
                )
        );
    }

    // 4. 복약 기록 삭제
    @DeleteMapping("/{recordId}")
    public ResponseEntity<Void> delete(
            Authentication authentication,
            @PathVariable Long recordId
    ) {
        medicationRecordService.delete(
                authentication.getName(),
                recordId
        );

        return ResponseEntity.noContent().build();
    }

    // 삭제 전 폐소리와 연결된 복약 기록 ID 조회
    @PostMapping("/linked-check")
    public ResponseEntity<List<Long>> checkLinkedRecords(
            Authentication authentication,
            @RequestBody List<Long> recordIds
    ) {
        return ResponseEntity.ok(
                medicationRecordService.getLinkedRecordIds(
                        authentication.getName(),
                        recordIds
                )
        );
    }

    // 여러 개 복약 기록 일괄 삭제
    @PostMapping("/batch-delete")
    public ResponseEntity<Void> deleteMultiple(
            Authentication authentication,
            @RequestBody List<Long> recordIds
    ) {
        medicationRecordService.deleteMultiple(
                authentication.getName(),
                recordIds
        );

        return ResponseEntity.noContent().build();
    }
}
