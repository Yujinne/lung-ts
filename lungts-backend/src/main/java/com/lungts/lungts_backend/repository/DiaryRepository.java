package com.lungts.lungts_backend.repository;

import com.lungts.lungts_backend.entity.Diary;
import com.lungts.lungts_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DiaryRepository extends JpaRepository<Diary, Long> {

    List<Diary> findByUserOrderByOccurredAtDesc(User user);
}