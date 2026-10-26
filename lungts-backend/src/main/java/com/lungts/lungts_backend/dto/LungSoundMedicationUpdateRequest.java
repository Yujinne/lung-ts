package com.lungts.lungts_backend.dto;

import com.lungts.lungts_backend.entity.MedicationStatus;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class LungSoundMedicationUpdateRequest {

    private MedicationStatus medicationStatus;

    private List<Long> medicationRecordIds;
}