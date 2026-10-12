package com.lungts.lungts_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

import java.util.Set;
import java.util.HashSet;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    // ID를 DB가 자동으로 생성
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // NULL 불가 + 이메일 중복 불가
    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    private String name;

    // 선택한 질환 목록
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
            name = "user_diseases",
            joinColumns = @JoinColumn(name = "user_id")
    )
    @Column(name = "disease", nullable = false)
    @Builder.Default
    private Set<String> diseases = new HashSet<>();

    // 기타 질환명
    @Column(name = "other_disease_name")
    private String otherDiseaseName;

    @CreationTimestamp
    private LocalDateTime createdAt;

    public void updateName(String name) {
        this.name = name;
    }

    public void updateDiseases(
            Set<String> diseases,
            String otherDiseaseName
    ) {
        this.diseases.clear();
        this.diseases.addAll(diseases);
        this.otherDiseaseName = otherDiseaseName;
    }

    public void updatePassword(String encodedPassword) {
        this.password = encodedPassword;
    }
}