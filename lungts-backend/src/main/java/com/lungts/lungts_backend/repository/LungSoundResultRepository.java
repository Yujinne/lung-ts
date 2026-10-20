package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.LungSoundResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface LungSoundResultRepository
        extends JpaRepository<LungSoundResult, Long> {

    List<LungSoundResult> findByUserIdOrderByRecordedAtDesc(Long userId);

    @Query("""
    SELECT DISTINCT l
    FROM LungSoundResult l
    JOIN l.medicationRecords m
    WHERE m.id IN :recordIds
    """)
    List<LungSoundResult> findByMedicationRecordIds(
            @Param("recordIds") List<Long> recordIds
    );

}