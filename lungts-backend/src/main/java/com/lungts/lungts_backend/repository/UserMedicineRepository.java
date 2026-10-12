package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.UserMedicine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserMedicineRepository
        extends JpaRepository<UserMedicine, Long> {

    // 사용자가 등록한 약 전체 조회
    List<UserMedicine> findByUserIdOrderByIdDesc(Long userId);

    // 같은 약이 이미 등록되어 있는지 확인
    Optional<UserMedicine> findByUserIdAndMedicineCode(
            Long userId,
            String medicineCode
    );
}