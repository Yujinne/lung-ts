package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.UserMedicineRequest;
import com.lungts.lungts_backend.dto.UserMedicineResponse;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.entity.UserMedicine;
import com.lungts.lungts_backend.repository.UserMedicineRepository;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.lungts.lungts_backend.dto.UserMedicineBulkRequest;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserMedicineService {

    private final UserMedicineRepository userMedicineRepository;
    private final UserRepository userRepository;
    private final MedicineService medicineService;

    @Transactional
    public UserMedicineResponse register(
            String email,
            UserMedicineRequest request
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        String medicineCode = request.getMedicineCode();

        if (medicineCode == null || medicineCode.isBlank()) {
            throw new IllegalArgumentException("의약품 식별번호가 필요합니다.");
        }

        // 엑셀에서 실제 의약품 조회
        Map<String, String> medicineInfo =
                medicineService.findMedicineByCode(medicineCode);

        if (medicineInfo == null) {
            throw new IllegalArgumentException(
                    "의약품 데이터에 존재하지 않는 약입니다."
            );
        }

        // 이미 등록한 약인지 확인
        UserMedicine existing = userMedicineRepository
                .findByUserIdAndMedicineCode(
                        user.getId(),
                        medicineCode
                )
                .orElse(null);

        if (existing != null) {
            existing.setDeleted(false); // 삭제했던 약이면 목록에 복구
            existing.setActive(true);   // 활성화
            return UserMedicineResponse.from(existing);
        }

        // 엑셀에서 검증한 이름으로 저장
        UserMedicine medicine = UserMedicine.builder()
                .user(user)
                .medicineCode(medicineInfo.get("itemSeq"))
                .medicineName(medicineInfo.get("itemName"))
                .active(true)
                .build();

        UserMedicine saved = userMedicineRepository.save(medicine);

        return UserMedicineResponse.from(saved);
    }

    // 내 약 목록 조회
    @Transactional(readOnly = true)
    public List<UserMedicineResponse> getMyMedicines(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        return userMedicineRepository
                .findByUserIdOrderByIdDesc(user.getId())
                .stream()
                .filter(medicine -> !medicine.isDeleted())
                .map(UserMedicineResponse::from)
                .toList();
    }

    // 약 사용 중단
    @Transactional
    public void deactivate(String email, Long medicineId) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserMedicine medicine = userMedicineRepository.findById(medicineId)
                .orElseThrow(() ->
                        new IllegalArgumentException("등록된 약을 찾을 수 없습니다."));

        if (!medicine.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("본인의 약만 수정할 수 있습니다.");
        }

        medicine.setActive(false);
    }

    @Transactional
    public void activate(String email, Long medicineId) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserMedicine medicine = userMedicineRepository.findById(medicineId)
                .orElseThrow(() ->
                        new IllegalArgumentException("등록된 약을 찾을 수 없습니다."));

        if (!medicine.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("본인의 약만 수정할 수 있습니다.");
        }

        if (medicine.isDeleted()) {
            throw new IllegalArgumentException("삭제된 약은 수정할 수 없습니다.");
        }

        medicine.setActive(true);
    }

    // 내 약 목록에서 삭제
    @Transactional
    public void delete(String email, Long medicineId) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserMedicine medicine = userMedicineRepository.findById(medicineId)
                .orElseThrow(() ->
                        new IllegalArgumentException("등록된 약을 찾을 수 없습니다."));

        // 본인이 등록한 약인지 확인
        if (!medicine.getUser().getId().equals(user.getId())) {
            throw new IllegalArgumentException("본인의 약만 삭제할 수 있습니다.");
        }

        if (medicine.isDeleted()) {
            throw new IllegalArgumentException("삭제된 약은 수정할 수 없습니다.");
        }

        if (medicine.isDeleted()) {
            throw new IllegalArgumentException("이미 삭제된 약입니다.");
        }

        medicine.setDeleted(true);
        medicine.setActive(false);
    }

    @Transactional
    public List<UserMedicineResponse> registerBulk(
            String email,
            UserMedicineBulkRequest request
    ) {
        if (request == null
                || request.getMedicines() == null
                || request.getMedicines().isEmpty()) {
            throw new IllegalArgumentException("등록할 약을 선택해 주세요.");
        }

        List<UserMedicineRequest> medicines = request.getMedicines();

        // 요청 내 중복 약 검사
        Set<String> medicineCodes = new HashSet<>();

        for (UserMedicineRequest medicine : medicines) {
            if (medicine == null
                    || medicine.getMedicineCode() == null
                    || medicine.getMedicineCode().isBlank()) {
                throw new IllegalArgumentException("잘못된 의약품 정보입니다.");
            }

            if (!medicineCodes.add(medicine.getMedicineCode())) {
                throw new IllegalArgumentException("중복 선택된 약이 있습니다.");
            }
        }

        // 모든 약을 하나의 트랜잭션에서 등록
        List<UserMedicineResponse> responses = new ArrayList<>();

        for (UserMedicineRequest medicine : medicines) {
            responses.add(register(email, medicine));
        }

        return responses;
    }
}