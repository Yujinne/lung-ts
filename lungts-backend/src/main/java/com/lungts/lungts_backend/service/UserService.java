package com.lungts.lungts_backend.service;

import com.lungts.lungts_backend.dto.LoginRequest;
import com.lungts.lungts_backend.dto.SignupRequest;
import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import com.lungts.lungts_backend.security.JwtTokenProvider;
import java.util.Set;
import java.util.HashSet;
import com.lungts.lungts_backend.dto.UserUpdateRequest;
import org.springframework.transaction.annotation.Transactional;
import com.lungts.lungts_backend.dto.PasswordChangeRequest;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    // 회원가입 사전 검증 (DB 저장 X)
    public void validateSignup(SignupRequest request) {

        // 이름 확인
        if (request.getName() == null ||
                request.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("이름을 입력해 주세요.");
        }

        // 이메일 확인
        String email = request.getEmail();

        if (email == null ||
                !email.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            throw new IllegalArgumentException("올바른 이메일을 입력해 주세요.");
        }

        // 비밀번호 확인
        String password = request.getPassword();

        if (password == null || password.length() < 4) {
            throw new IllegalArgumentException(
                    "비밀번호는 4자 이상 입력해 주세요."
            );
        }

        // 이메일 중복 확인
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("이미 사용 중인 이메일입니다.");
        }

        Set<String> diseases = request.getDiseases();

        if (diseases == null || diseases.isEmpty()) {
            throw new IllegalArgumentException("질환을 선택해 주세요.");
        }

        if (!Set.of("ASTHMA", "COPD", "OTHER", "NONE")
                .containsAll(diseases)) {
            throw new IllegalArgumentException("올바르지 않은 질환 선택입니다.");
        }

        if (diseases.contains("NONE") && diseases.size() > 1) {
            throw new IllegalArgumentException(
                    "'없음'은 다른 질환과 함께 선택할 수 없습니다."
            );
        }

        if (diseases.contains("OTHER") &&
                (request.getOtherDiseaseName() == null ||
                        request.getOtherDiseaseName().trim().isEmpty())) {
            throw new IllegalArgumentException("기타 질환명을 입력해 주세요.");
        }
    }



    // 회원가입 (DB 저장 O)
    public void signup(SignupRequest request) {

        // 회원가입 조건 재검사
        validateSignup(request);

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName().trim())
                .diseases(new HashSet<>(request.getDiseases()))
                .otherDiseaseName(
                        request.getDiseases().contains("OTHER")
                                ? request.getOtherDiseaseName().trim()
                                : null
                )
                .build();

        userRepository.save(user);
    }

    // 로그인
    public String login(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() ->
                        new IllegalArgumentException("존재하지 않는 이메일입니다."));

        if (user.isDeleted()) {
            throw new IllegalArgumentException("탈퇴한 계정입니다.");
        }

        if (!passwordEncoder.matches(
                request.getPassword(),
                user.getPassword())) {

            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }

        return jwtTokenProvider.createToken(user.getEmail());
    }

    // 현재 로그인한 사용자 정보 조회
    public User getMyInfo(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    // 회원 정보 수정
    @Transactional
    public void updateMyInfo(String email, UserUpdateRequest request) {

        // 1. 로그인한 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 2. 이름 검증
        String name = request.getName();

        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("이름을 입력해 주세요.");
        }

        // 3. 질환 선택 검증
        Set<String> diseases = request.getDiseases();

        if (diseases == null || diseases.isEmpty()) {
            throw new IllegalArgumentException("질환을 선택해 주세요.");
        }

        if (!Set.of("ASTHMA", "COPD", "OTHER", "NONE")
                .containsAll(diseases)) {
            throw new IllegalArgumentException("올바르지 않은 질환 선택입니다.");
        }

        if (diseases.contains("NONE") && diseases.size() > 1) {
            throw new IllegalArgumentException(
                    "'없음'은 다른 질환과 함께 선택할 수 없습니다."
            );
        }

        // 4. 기타 질환명 검증
        String otherDiseaseName = null;

        if (diseases.contains("OTHER")) {
            otherDiseaseName = request.getOtherDiseaseName();

            if (otherDiseaseName == null ||
                    otherDiseaseName.trim().isEmpty()) {
                throw new IllegalArgumentException("기타 질환명을 입력해 주세요.");
            }

            otherDiseaseName = otherDiseaseName.trim();
        }

        // 5. 사용자 정보 변경
        user.updateName(name.trim());
        user.updateDiseases(diseases, otherDiseaseName);
    }

    // 비밀번호 변경
    @Transactional
    public void changePassword(
            String email,
            PasswordChangeRequest request
    ) {
        // 1. 로그인한 사용자 조회
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 2. 입력값 확인
        String currentPassword = request.getCurrentPassword();
        String newPassword = request.getNewPassword();
        String confirmPassword = request.getConfirmPassword();

        if (currentPassword == null ||
                newPassword == null ||
                confirmPassword == null) {
            throw new IllegalArgumentException("비밀번호를 모두 입력해 주세요.");
        }

        // 3. 현재 비밀번호 검증
        if (!passwordEncoder.matches(
                currentPassword, user.getPassword())) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        // 4. 새 비밀번호 확인
        if (!newPassword.equals(confirmPassword)) {
            throw new IllegalArgumentException("새 비밀번호가 일치하지 않습니다.");
        }

        // 5. 기존 비밀번호와 동일한지 확인
        if (passwordEncoder.matches(
                newPassword, user.getPassword())) {
            throw new IllegalArgumentException(
                    "기존 비밀번호와 다른 비밀번호를 입력해 주세요."
            );
        }

        // 6. 새 비밀번호 유효성 검사
        if (newPassword.length() < 8) {
            throw new IllegalArgumentException(
                    "비밀번호는 8자 이상이어야 합니다."
            );
        }

        // 7. BCrypt 암호화
        String encodedPassword = passwordEncoder.encode(newPassword);

        // 8. 비밀번호 변경
        user.updatePassword(encodedPassword);
    }

    // 회원 탈퇴
    @Transactional
    public void withdraw(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        if (user.isDeleted()) {
            throw new IllegalArgumentException("이미 탈퇴한 회원입니다.");
        }

        user.withdraw();
    }
}