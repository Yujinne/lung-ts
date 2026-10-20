package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.MedicationStatus;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class LungSoundResultRequest {

    private LocalDateTime recordedAt;
    private String audioPath;

    // BEFORE: 복약 전, AFTER: 복약 후
    private MedicationStatus medicationStatus;

    // 복약 후 측정 시 연결할 복약 기록 ID
    private Long medicationRecordId;

    private List<Long> medicationRecordIds;
}