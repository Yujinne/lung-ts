package com.lungts.lungts_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Entity
@Table(name = "lung_sound_results")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LungSoundResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDateTime recordedAt;

    @Column(length = 500)
    private String audioPath;

    // 복약 전 / 복약 후 상태
    @Enumerated(EnumType.STRING)
    @Column(name = "medication_status", length = 20)
    private MedicationStatus medicationStatus;

    // 복약 후 측정일 때 연결할 복약 기록
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "lung_sound_medication_records",
            joinColumns = @JoinColumn(name = "lung_sound_result_id"),
            inverseJoinColumns = @JoinColumn(name = "medication_record_id")
    )
    @Builder.Default
    private List<MedicationRecord> medicationRecords = new ArrayList<>();

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public void unlinkMedicationRecords(List<Long> recordIds) {
        this.medicationRecords.removeIf(
                record -> recordIds.contains(record.getId())
        );

        if (this.medicationRecords.isEmpty()
                && this.medicationStatus == MedicationStatus.AFTER) {
            this.medicationStatus = MedicationStatus.UNKNOWN;
        }
    }
}