package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.LungSoundResult;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class LungSoundResultResponse {

    private Long id;
    private LocalDateTime recordedAt;
    private String audioPath;
    private LocalDateTime createdAt;

    public static LungSoundResultResponse from(LungSoundResult result) {
        return LungSoundResultResponse.builder()
                .id(result.getId())
                .recordedAt(result.getRecordedAt())
                .audioPath(result.getAudioPath())
                .createdAt(result.getCreatedAt())
                .build();
    }
}