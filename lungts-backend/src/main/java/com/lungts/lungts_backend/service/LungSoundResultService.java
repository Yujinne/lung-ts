package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.LungSoundResultRequest;
import com.lungts.lungts_backend.dto.LungSoundResultResponse;
import com.lungts.lungts_backend.entity.LungSoundResult;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.repository.LungSoundResultRepository;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.lungts.lungts_backend.entity.MedicationRecord;
import com.lungts.lungts_backend.entity.MedicationStatus;
import com.lungts.lungts_backend.repository.MedicationRecordRepository;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LungSoundResultService {

    private final LungSoundResultRepository lungSoundResultRepository;
    private final UserRepository userRepository;
    private final MedicationRecordRepository medicationRecordRepository;

    @Transactional
    public LungSoundResultResponse create(
            String email,
            LungSoundResultRequest request
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        if (request.getRecordedAt() == null) {
            throw new IllegalArgumentException("측정 시간이 필요합니다.");
        }

        MedicationStatus status = request.getMedicationStatus();

        if (status == null) {
            throw new IllegalArgumentException("복약 전/후를 선택해주세요.");
        }

        List<MedicationRecord> medicationRecords = new java.util.ArrayList<>();

        if (status == MedicationStatus.AFTER) {

            List<Long> recordIds = request.getMedicationRecordIds();

            // 기존 단일 ID 요청도 지원
            if ((recordIds == null || recordIds.isEmpty())
                    && request.getMedicationRecordId() != null) {
                recordIds = List.of(request.getMedicationRecordId());
            }

            if (recordIds == null || recordIds.isEmpty()) {
                throw new IllegalArgumentException("복약 기록을 선택해주세요.");
            }

            if (recordIds.stream().anyMatch(id -> id == null)
                    || recordIds.stream().distinct().count() != recordIds.size()) {
                throw new IllegalArgumentException("복약 기록 ID가 올바르지 않습니다.");
            }

            medicationRecords = medicationRecordRepository.findAllById(recordIds);

            if (medicationRecords.size() != recordIds.size()) {
                throw new IllegalArgumentException("일부 복약 기록을 찾을 수 없습니다.");
            }

            for (MedicationRecord medicationRecord : medicationRecords) {

                if (!medicationRecord.getUser().getId().equals(user.getId())) {
                    throw new IllegalArgumentException(
                            "본인의 복약 기록만 선택할 수 있습니다."
                    );
                }

                if (medicationRecord.getTakenAt().isAfter(request.getRecordedAt())) {
                    throw new IllegalArgumentException(
                            "측정 시간보다 나중에 복용한 약은 선택할 수 없습니다."
                    );
                }
            }

        } else if (request.getMedicationRecordId() != null
                || (request.getMedicationRecordIds() != null
                && !request.getMedicationRecordIds().isEmpty())) {

            throw new IllegalArgumentException(
                    "복약 전 측정에는 복약 기록을 연결할 수 없습니다."
            );
        }

        LungSoundResult result = LungSoundResult.builder()
                .user(user)
                .recordedAt(request.getRecordedAt())
                .audioPath(request.getAudioPath())
                .medicationStatus(status)
                .medicationRecords(medicationRecords)
                .build();

        LungSoundResult saved = lungSoundResultRepository.save(result);

        return LungSoundResultResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<LungSoundResultResponse> getAll(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        return lungSoundResultRepository
                .findByUserIdOrderByRecordedAtDesc(user.getId())
                .stream()
                .map(LungSoundResultResponse::from)
                .toList();
    }

    @Transactional
    public void delete(String email, Long resultId) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        LungSoundResult result =
                lungSoundResultRepository.findById(resultId)
                        .orElseThrow(() ->
                                new IllegalArgumentException(
                                        "측정 기록을 찾을 수 없습니다."
                                )
                        );

        if (!result.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException(
                    "본인의 측정 기록만 삭제할 수 있습니다."
            );
        }

        lungSoundResultRepository.delete(result);
    }

    @Transactional
    public LungSoundResultResponse createWithFile(
            String email,
            LocalDateTime recordedAt,
            String audioPath,
            MedicationStatus medicationStatus,
            List<Long> medicationRecordIds
    ) {
        LungSoundResultRequest request = new LungSoundResultRequest();

        request.setRecordedAt(recordedAt);
        request.setAudioPath(audioPath);
        request.setMedicationStatus(medicationStatus);
        request.setMedicationRecordIds(medicationRecordIds);

        return create(email, request);
    }

    @Transactional(readOnly = true)
    public String getAudioPath(String email, Long resultId) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        LungSoundResult result = lungSoundResultRepository.findById(resultId)
                .orElseThrow(() ->
                        new IllegalArgumentException("측정 기록을 찾을 수 없습니다.")
                );

        // 본인 기록인지 확인
        if (!result.getUser().getId().equals(user.getId())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "본인의 측정 기록만 조회할 수 있습니다."
            );
        }

        // WAV 파일 경로 확인
        String audioPath = result.getAudioPath();

        if (audioPath == null || audioPath.isBlank()) {
            throw new IllegalArgumentException(
                    "이 측정 기록에는 저장된 음성 파일이 없습니다."
            );
        }

        return audioPath;
    }
}