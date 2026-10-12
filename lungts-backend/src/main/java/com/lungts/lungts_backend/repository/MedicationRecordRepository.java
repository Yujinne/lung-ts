package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.MedicationRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface MedicationRecordRepository
        extends JpaRepository<MedicationRecord, Long> {

    // 로그인한 사용자의 복약 기록 전체 조회
    List<MedicationRecord> findByUserIdOrderByTakenAtDesc(
            Long userId
    );

    // 특정 날짜 또는 기간의 복약 기록 조회
    List<MedicationRecord> findByUserIdAndTakenAtGreaterThanEqualAndTakenAtLessThanOrderByTakenAtAsc(
            Long userId,
            LocalDateTime start,
            LocalDateTime end
    );

    // 특정 사용자의 복약 기록 하나 조회
    Optional<MedicationRecord> findByIdAndUserId(
            Long id,
            Long userId
    );
}