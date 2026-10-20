package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.LungSoundResult;
import com.lungts.lungts_backend.entity.MedicationStatus;
import lombok.Builder;
import lombok.Getter;
import java.util.List;
import java.time.LocalDateTime;

@Getter
@Builder
public class LungSoundResultResponse {

    private Long id;
    private LocalDateTime recordedAt;
    private String audioPath;
    private MedicationStatus medicationStatus;
    private Long medicationRecordId;
    private List<Long> medicationRecordIds;
    private LocalDateTime createdAt;

    public static LungSoundResultResponse from(LungSoundResult result) {

        List<Long> recordIds = result.getMedicationRecords()
                .stream()
                .map(record -> record.getId())
                .toList();

        return LungSoundResultResponse.builder()
                .id(result.getId())
                .recordedAt(result.getRecordedAt())
                .audioPath(result.getAudioPath())
                .medicationStatus(result.getMedicationStatus())
                .medicationRecordId(
                        recordIds.size() == 1 ? recordIds.get(0) : null
                )
                .medicationRecordIds(recordIds)
                .createdAt(result.getCreatedAt())
                .build();
    }
}