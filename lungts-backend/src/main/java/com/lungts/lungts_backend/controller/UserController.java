package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.entity.User;
import com.lungts.lungts_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.lungts.lungts_backend.dto.UserUpdateRequest;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.Map;
import com.lungts.lungts_backend.dto.PasswordChangeRequest;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getMyInfo(
            Authentication authentication
    ) {
        String email = authentication.getName();

        User user = userService.getMyInfo(email);

        return ResponseEntity.ok(Map.of(
                "name", user.getName(),
                "email", user.getEmail(),
                "diseases", user.getDiseases(),
                "otherDiseaseName",
                user.getOtherDiseaseName() == null
                        ? ""
                        : user.getOtherDiseaseName()
        ));
    }

    // 회원 정보 수정
    @PutMapping("/me")
    public ResponseEntity<Map<String, String>> updateMyInfo(
            Authentication authentication,
            @RequestBody UserUpdateRequest request
    ) {
        String email = authentication.getName();

        userService.updateMyInfo(email, request);

        return ResponseEntity.ok(
                Map.of("message", "회원 정보가 수정되었습니다.")
        );
    }

    // 비밀번호 변경
    @PutMapping("/me/password")
    public ResponseEntity<Map<String, String>> changePassword(
            Authentication authentication,
            @RequestBody PasswordChangeRequest request
    ) {
        String email = authentication.getName();

        userService.changePassword(email, request);

        return ResponseEntity.ok(
                Map.of("message", "비밀번호가 변경되었습니다.")
        );
    }
}