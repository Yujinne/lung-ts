package com.lungts.lungts_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "medication_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedicationRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 복약 기록을 작성한 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 내 약 목록에서 선택한 약
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_medicine_id", nullable = false)
    private UserMedicine userMedicine;

    // 실제 약을 복용한 날짜와 시간
    @Column(nullable = false)
    private LocalDateTime takenAt;

    // 실제 복용량
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal dose;

    // 복용 단위 (정, puff, mL 등)
    @Column(nullable = false)
    private String doseUnit;

    // 복약 기록 생성 시간
    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    // 복약 기록 수정 시간
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}