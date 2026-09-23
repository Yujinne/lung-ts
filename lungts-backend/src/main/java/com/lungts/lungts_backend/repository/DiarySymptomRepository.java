package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.Diary;
import com.lungts.lungts_backend.entity.DiarySymptom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DiarySymptomRepository
        extends JpaRepository<DiarySymptom, Long> {

    List<DiarySymptom> findByDiary(Diary diary);

    void deleteByDiary(Diary diary);
}