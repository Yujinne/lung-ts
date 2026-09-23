package com.lungts.lungts_backend.controller;

import com.lungts.lungts_backend.dto.LoginRequest;
import com.lungts.lungts_backend.dto.SignupRequest;
import com.lungts.lungts_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody SignupRequest request) {
        userService.signup(request);
        return ResponseEntity.ok("회원가입 성공");
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody LoginRequest request) {

        String token = userService.login(request);

        return ResponseEntity.ok(token);
    }
}