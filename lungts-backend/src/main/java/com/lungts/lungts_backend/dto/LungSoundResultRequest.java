package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
public class LungSoundResultRequest {

    private LocalDateTime recordedAt;
    private String audioPath;
}