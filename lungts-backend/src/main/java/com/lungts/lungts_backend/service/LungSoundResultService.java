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

import java.util.List;

@Service
@RequiredArgsConstructor
public class LungSoundResultService {

    private final LungSoundResultRepository lungSoundResultRepository;
    private final UserRepository userRepository;

    @Transactional
    public LungSoundResultResponse create(
            String email,
            LungSoundResultRequest request
    ) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        LungSoundResult result = LungSoundResult.builder()
                .user(user)
                .recordedAt(request.getRecordedAt())
                .audioPath(request.getAudioPath())
                .build();

        LungSoundResult saved =
                lungSoundResultRepository.save(result);

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
}