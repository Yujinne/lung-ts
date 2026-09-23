package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@NoArgsConstructor
public class DiaryRequest {

    private LocalDateTime occurredAt;

    private List<String> symptoms;

    private String memo;
}