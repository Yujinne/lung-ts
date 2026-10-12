package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
public class MedicationRecordRequest {

    // 내 약 목록에서 선택한 약 ID
    private Long userMedicineId;

    // 실제 복용한 날짜와 시간
    private LocalDateTime takenAt;

    // 실제 복용량
    private BigDecimal dose;
}