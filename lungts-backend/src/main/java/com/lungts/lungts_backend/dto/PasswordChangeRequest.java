package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PasswordChangeRequest {

    private String currentPassword;

    private String newPassword;

    private String confirmPassword;
}