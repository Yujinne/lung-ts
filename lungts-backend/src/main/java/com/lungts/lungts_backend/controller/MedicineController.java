package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.service.MedicineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/medicines")
@RequiredArgsConstructor
public class MedicineController {

    private final MedicineService medicineService;

    // 약 이름으로 여러 의약품 검색
    @GetMapping("/search-list")
    public ResponseEntity<List<Map<String, String>>> searchMedicines(
            @RequestParam String name
    ) {
        List<Map<String, String>> medicines =
                medicineService.searchMedicines(name);

        return ResponseEntity.ok(medicines);
    }
}