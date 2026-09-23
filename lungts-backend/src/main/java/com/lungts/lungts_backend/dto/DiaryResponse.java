package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.Diary;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
public class DiaryResponse {

    private final Long id;
    private final LocalDateTime occurredAt;
    private final List<String> symptoms;
    private final String memo;
    private final LocalDateTime createdAt;

    public DiaryResponse(
            Diary diary,
            List<String> symptoms
    ) {
        this.id = diary.getId();
        this.occurredAt = diary.getOccurredAt();
        this.symptoms = symptoms;
        this.memo = diary.getMemo();
        this.createdAt = diary.getCreatedAt();
    }
}