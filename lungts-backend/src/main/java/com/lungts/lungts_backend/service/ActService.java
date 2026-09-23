package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.ActResultRequest;
import com.lungts.lungts_backend.dto.ActResultResponse;
import com.lungts.lungts_backend.entity.ActResult;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.repository.ActResultRepository;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ActService {

    private final ActResultRepository actResultRepository;
    private final UserRepository userRepository;

    public void saveResult(String email, ActResultRequest request) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        ActResult actResult = ActResult.builder()
                .user(user)
                .score(request.getScore())
                .build();

        actResultRepository.save(actResult);
    }

    public List<ActResultResponse> getResults(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다.")
                );

        return actResultRepository
                .findByUserOrderByCreatedAtDesc(user)
                .stream()
                .map(ActResultResponse::new)
                .toList();
    }
}