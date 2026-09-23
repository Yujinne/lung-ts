package com.lungts.lungts_backend.dto;

import lombok.Getter;

import java.util.Map;

@Getter
public class SymptomStatisticsResponse {

    private final Map<String, Integer> symptomCounts;

    private final Map<String, Map<String, Integer>> symptomTimeData;

    public SymptomStatisticsResponse(
            Map<String, Integer> symptomCounts,
            Map<String, Map<String, Integer>> symptomTimeData
    ) {
        this.symptomCounts = symptomCounts;
        this.symptomTimeData = symptomTimeData;
    }
}