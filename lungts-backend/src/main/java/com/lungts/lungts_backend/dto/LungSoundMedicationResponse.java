
package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.MedicationRecord;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Builder
public class LungSoundMedicationResponse {

    private Long id;
    private String medicineName;
    private LocalDateTime takenAt;
    private BigDecimal dose;
    private String doseUnit;

    public static LungSoundMedicationResponse from(MedicationRecord record) {
        return LungSoundMedicationResponse.builder()
                .id(record.getId())
                .medicineName(record.getUserMedicine().getMedicineName())
                .takenAt(record.getTakenAt())
                .dose(record.getDose())
                .doseUnit(record.getDoseUnit())
                .build();
    }
}
