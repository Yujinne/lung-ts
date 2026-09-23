package com.lungts.lungts_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "diary_symptoms")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiarySymptom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "diary_id", nullable = false)
    private Diary diary;

    @Column(nullable = false)
    private String symptom;
}