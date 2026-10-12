package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.MedicationRecord;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Builder
public class MedicationRecordResponse {

    private Long id;

    private Long userMedicineId;

    private String medicineName;

    private LocalDateTime takenAt;

    private BigDecimal dose;

    private String doseUnit;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    public static MedicationRecordResponse from(
            MedicationRecord record
    ) {
        return MedicationRecordResponse.builder()
                .id(record.getId())
                .userMedicineId(record.getUserMedicine().getId())
                .medicineName(record.getUserMedicine().getMedicineName())
                .takenAt(record.getTakenAt())
                .dose(record.getDose())
                .doseUnit(record.getDoseUnit())
                .createdAt(record.getCreatedAt())
                .updatedAt(record.getUpdatedAt())
                .build();
    }
}