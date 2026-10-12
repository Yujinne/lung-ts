package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class UserMedicineBulkRequest {

    private List<UserMedicineRequest> medicines;
}