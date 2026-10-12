package com.lungts.lungts_backend.service;

import org.apache.poi.ss.usermodel.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import org.apache.poi.ss.usermodel.DataFormatter;


@Service
public class MedicineService {
    // 약 이름으로 여러 의약품 검색
    public List<Map<String, String>> searchMedicines(String name) {

        List<Map<String, String>> results = new ArrayList<>();

        if (name == null || name.isBlank()) {
            return results;
        }

        try {
            ClassPathResource resource =
                    new ClassPathResource("data/drugs.xlsx");

            try (InputStream inputStream = resource.getInputStream();
                 Workbook workbook = WorkbookFactory.create(inputStream)) {

                Sheet sheet = workbook.getSheetAt(0);
                Row headerRow = sheet.getRow(0);

                Map<String, Integer> columns = new HashMap<>();

                for (Cell cell : headerRow) {
                    columns.put(
                            cell.getStringCellValue().trim(),
                            cell.getColumnIndex()
                    );
                }

                Integer itemNameIndex = columns.get("itemName");
                Integer itemSeqIndex = columns.get("itemSeq");

                if (itemNameIndex == null || itemSeqIndex == null) {
                    throw new IllegalStateException(
                            "엑셀에 itemName 또는 itemSeq 컬럼이 없습니다."
                    );
                }

                String keyword = name.trim().toLowerCase();

                for (int i = 1; i <= sheet.getLastRowNum(); i++) {

                    Row row = sheet.getRow(i);

                    if (row == null) {
                        continue;
                    }

                    String itemName =
                            getCellValue(row.getCell(itemNameIndex));

                    if (!itemName.toLowerCase().contains(keyword)) {
                        continue;
                    }

                    Map<String, String> medicine = new HashMap<>();

                    medicine.put("itemName", itemName);

                    addColumn(medicine, row, columns, "itemSeq");
                    addColumn(medicine, row, columns, "itemImage");
                    addColumn(medicine, row, columns, "efcyQesitm");
                    addColumn(medicine, row, columns, "useMethodQesitm");

                    // 식별번호가 없는 데이터는 등록 후보에서 제외
                    if (medicine.getOrDefault("itemSeq", "").isBlank()) {
                        continue;
                    }

                    results.add(medicine);

                    // 한 번에 최대 20개 반환
                    if (results.size() >= 20) {
                        break;
                    }
                }

            }

            } catch (Exception e) {
                throw new RuntimeException(
                        "의약품 목록 검색 중 오류가 발생했습니다.",
                        e
                );
            }

        return results;
    }

    // 의약품 식별번호로 정확한 약 조회
    public Map<String, String> findMedicineByCode(String medicineCode) {

        try {
            ClassPathResource resource =
                    new ClassPathResource("data/drugs.xlsx");

            try (InputStream inputStream = resource.getInputStream();
                 Workbook workbook = WorkbookFactory.create(inputStream)) {

                Sheet sheet = workbook.getSheetAt(0);
                Row headerRow = sheet.getRow(0);

                Map<String, Integer> columns = new HashMap<>();

                for (Cell cell : headerRow) {
                    columns.put(
                            cell.getStringCellValue(),
                            cell.getColumnIndex()
                    );
                }

                Integer itemSeqIndex = columns.get("itemSeq");
                Integer itemNameIndex = columns.get("itemName");

                if (itemSeqIndex == null || itemNameIndex == null) {
                    throw new IllegalStateException(
                            "데이터에 itemSeq 또는 itemName 컬럼이 없습니다."
                    );
                }

                for (int i = 1; i <= sheet.getLastRowNum(); i++) {

                    Row row = sheet.getRow(i);

                    if (row == null) {
                        continue;
                    }

                    String itemSeq = getCellValue(
                            row.getCell(itemSeqIndex)
                    );

                    if (medicineCode.equals(itemSeq)) {

                        Map<String, String> result = new HashMap<>();

                        result.put("itemSeq", itemSeq);

                        result.put(
                                "itemName",
                                getCellValue(row.getCell(itemNameIndex))
                        );

                        return result;
                    }
                }
            }

        } catch (Exception e) {
            throw new RuntimeException(
                    "의약품 식별번호 조회 중 오류가 발생했습니다.",
                    e
            );
        }

        return null;
    }

    private void addColumn(
            Map<String, String> result,
            Row row,
            Map<String, Integer> columns,
            String columnName
    ) {

        Integer index = columns.get(columnName);

        if (index != null) {
            result.put(
                    columnName,
                    getCellValue(row.getCell(index))
            );
        }
    }

    private final DataFormatter dataFormatter = new DataFormatter();

    private String getCellValue(Cell cell) {

        if (cell == null) {
            return "";
        }

        return dataFormatter.formatCellValue(cell).trim();
    }
}