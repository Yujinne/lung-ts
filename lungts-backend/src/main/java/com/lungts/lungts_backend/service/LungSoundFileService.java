package com.lungts.lungts_backend.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class LungSoundFileService {

    private static final Path UPLOAD_DIR =
            Paths.get("uploads", "lung-sounds").toAbsolutePath().normalize();

    public String saveWavFile(MultipartFile file) throws IOException {

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("WAV 파일을 선택해주세요.");
        }

        // 파일 크기 제한: 20MB
        if (file.getSize() > 20 * 1024 * 1024) {
            throw new IllegalArgumentException("20MB 이하 파일만 업로드할 수 있습니다.");
        }

        String originalName = file.getOriginalFilename();

        if (originalName == null ||
                !originalName.toLowerCase().endsWith(".wav")) {
            throw new IllegalArgumentException("WAV 파일만 업로드할 수 있습니다.");
        }

        // 실제 WAV 파일인지 헤더 확인
        byte[] header = new byte[12];

        try (var input = file.getInputStream()) {
            if (input.readNBytes(header, 0, 12) != 12 ||
                    !new String(header, 0, 4,
                            java.nio.charset.StandardCharsets.US_ASCII).equals("RIFF") ||
                    !new String(header, 8, 4,
                            java.nio.charset.StandardCharsets.US_ASCII).equals("WAVE")) {
                throw new IllegalArgumentException("올바른 WAV 파일이 아닙니다.");
            }
        }

        Files.createDirectories(UPLOAD_DIR);

        String storedName = UUID.randomUUID() + ".wav";
        Path destination = UPLOAD_DIR.resolve(storedName);

        file.transferTo(destination);

        return "uploads/lung-sounds/" + storedName;
    }

    public Path getWavFile(String audioPath) throws IOException {

        if (audioPath == null || audioPath.isBlank()) {
            throw new IllegalArgumentException("음성 파일 경로가 없습니다.");
        }

        Path fileName = Paths.get(audioPath).getFileName();

        if (fileName == null) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        Path filePath = UPLOAD_DIR.resolve(fileName).normalize();

        if (!filePath.startsWith(UPLOAD_DIR)) {
            throw new IllegalArgumentException("잘못된 파일 경로입니다.");
        }

        if (!Files.isRegularFile(filePath)) {
            throw new java.io.FileNotFoundException(
                    "WAV 파일을 찾을 수 없습니다."
            );
        }

        return filePath;
    }
}