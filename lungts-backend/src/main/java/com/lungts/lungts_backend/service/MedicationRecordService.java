
package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.MedicationRecordRequest;
import com.lungts.lungts_backend.dto.MedicationRecordResponse;
import com.lungts.lungts_backend.entity.MedicationRecord;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.entity.UserMedicine;
import com.lungts.lungts_backend.repository.MedicationRecordRepository;
import com.lungts.lungts_backend.repository.UserMedicineRepository;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MedicationRecordService {

    private final MedicationRecordRepository medicationRecordRepository;
    private final UserMedicineRepository userMedicineRepository;
    private final UserRepository userRepository;

    // 로그인한 사용자 조회
    private User getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    // 요청 데이터 검증
    private void validateRequest(MedicationRecordRequest request) {
        if (request == null
                || request.getUserMedicineId() == null
                || request.getTakenAt() == null
                || request.getDose() == null) {
            throw new IllegalArgumentException("필수 입력값이 누락되었습니다.");
        }

        if (request.getDose().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("복용량은 0보다 커야 합니다.");
        }
    }

    // 내 약 목록에서 약 확인
    private UserMedicine getMyMedicine(Long userId, Long medicineId) {
        UserMedicine medicine = userMedicineRepository.findById(medicineId)
                .orElseThrow(() ->
                        new IllegalArgumentException("등록된 약을 찾을 수 없습니다."));

        if (!medicine.getUser().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 약만 기록할 수 있습니다.");
        }

        if (!medicine.isActive()) {
            throw new IllegalArgumentException("사용 중단한 약은 새로 기록할 수 없습니다.");
        }

        if (medicine.getDoseUnit() == null
                || medicine.getDoseUnit().isBlank()) {
            throw new IllegalArgumentException("약의 복용 단위가 설정되지 않았습니다.");
        }

        return medicine;
    }

    // 복약 기록 등록
    @Transactional
    public MedicationRecordResponse create(
            String email,
            MedicationRecordRequest request
    ) {
        validateRequest(request);

        User user = getUser(email);

        UserMedicine medicine = getMyMedicine(
                user.getId(),
                request.getUserMedicineId()
        );

        MedicationRecord record = MedicationRecord.builder()
                .user(user)
                .userMedicine(medicine)
                .takenAt(request.getTakenAt())
                .dose(request.getDose())
                .doseUnit(medicine.getDoseUnit())
                .build();

        return MedicationRecordResponse.from(
                medicationRecordRepository.save(record)
        );
    }

    // 날짜별 복약 기록 조회
    @Transactional(readOnly = true)
    public List<MedicationRecordResponse> getByDate(
            String email,
            LocalDate date
    ) {
        User user = getUser(email);

        return medicationRecordRepository
                .findByUserIdAndTakenAtGreaterThanEqualAndTakenAtLessThanOrderByTakenAtAsc(
                        user.getId(),
                        date.atStartOfDay(),
                        date.plusDays(1).atStartOfDay()
                )
                .stream()
                .map(MedicationRecordResponse::from)
                .toList();
    }

    // 복약 기록 수정
    @Transactional
    public MedicationRecordResponse update(
            String email,
            Long recordId,
            MedicationRecordRequest request
    ) {
        validateRequest(request);

        User user = getUser(email);

        MedicationRecord record = medicationRecordRepository
                .findByIdAndUserId(recordId, user.getId())
                .orElseThrow(() ->
                        new IllegalArgumentException("복약 기록을 찾을 수 없습니다."));

        UserMedicine medicine = getMyMedicine(
                user.getId(),
                request.getUserMedicineId()
        );

        record.setUserMedicine(medicine);
        record.setTakenAt(request.getTakenAt());
        record.setDose(request.getDose());
        record.setDoseUnit(medicine.getDoseUnit());

        return MedicationRecordResponse.from(record);
    }

    // 복약 기록 삭제
    @Transactional
    public void delete(String email, Long recordId) {
        User user = getUser(email);

        MedicationRecord record = medicationRecordRepository
                .findByIdAndUserId(recordId, user.getId())
                .orElseThrow(() ->
                        new IllegalArgumentException("복약 기록을 찾을 수 없습니다."));

        medicationRecordRepository.delete(record);
    }
}
