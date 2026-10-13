package com.lungts.lungts_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_medicines")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserMedicine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 약을 등록한 사용자
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 공공데이터 의약품 식별번호(itemSeq)
    @Column(nullable = false)
    private String medicineCode;

    // 약 이름
    @Column(nullable = false)
    private String medicineName;

    // 현재 사용 중인지
    @Builder.Default
    private boolean active = true;

    // 약 목록에서 삭제된 약인지
    @Builder.Default
    @Column(nullable = false)
    private boolean deleted = false;

    @CreationTimestamp
    private LocalDateTime createdAt;
}