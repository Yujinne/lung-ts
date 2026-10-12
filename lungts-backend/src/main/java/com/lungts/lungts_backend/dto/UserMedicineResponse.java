package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.UserMedicine;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserMedicineResponse {

    private Long id;
    private String medicineCode;
    private String medicineName;
    private String doseUnit;
    private boolean active;

    public static UserMedicineResponse from(UserMedicine medicine) {
        return UserMedicineResponse.builder()
                .id(medicine.getId())
                .medicineCode(medicine.getMedicineCode())
                .medicineName(medicine.getMedicineName())
                .doseUnit(medicine.getDoseUnit())
                .active(medicine.isActive())
                .build();
    }
}