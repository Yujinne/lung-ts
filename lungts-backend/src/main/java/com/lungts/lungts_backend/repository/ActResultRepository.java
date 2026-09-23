package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.ActResult;
import com.lungts.lungts_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ActResultRepository extends JpaRepository<ActResult, Long> {

    List<ActResult> findByUserOrderByCreatedAtDesc(User user);
}