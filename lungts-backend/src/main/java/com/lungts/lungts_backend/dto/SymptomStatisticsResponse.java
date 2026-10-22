package com.lungts.lungts_backend.dto;

import lombok.Getter;
import java.util.Map;

@Getter
public class SymptomStatisticsResponse {

    // 증상 종류별 발생 횟수
    private final Map<String, Integer> symptomCounts;

    // 시간대별 증상 발생 횟수
    private final Map<String, Map<String, Integer>> symptomTimeData;

    // 날짜별 증상 발생 횟수
    private final Map<String, Map<String, Integer>> symptomDateData;

    public SymptomStatisticsResponse(
            Map<String, Integer> symptomCounts,
            Map<String, Map<String, Integer>> symptomTimeData,
            Map<String, Map<String, Integer>> symptomDateData
    ) {
        this.symptomCounts = symptomCounts;
        this.symptomTimeData = symptomTimeData;
        this.symptomDateData = symptomDateData;
    }
}