package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.ActResult;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class ActResultResponse {

    private final Long id;
    private final Integer score;
    private final LocalDateTime createdAt;

    public ActResultResponse(ActResult actResult) {
        this.id = actResult.getId();
        this.score = actResult.getScore();
        this.createdAt = actResult.getCreatedAt();
    }
}