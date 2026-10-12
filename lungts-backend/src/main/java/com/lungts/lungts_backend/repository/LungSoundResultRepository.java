package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.LungSoundResult;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LungSoundResultRepository
        extends JpaRepository<LungSoundResult, Long> {

    List<LungSoundResult> findByUserIdOrderByRecordedAtDesc(Long userId);
}