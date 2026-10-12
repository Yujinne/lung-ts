package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Set;

@Getter
@NoArgsConstructor
public class SignupRequest {

    private String email;
    private String password;
    private String name;
    private Set<String> diseases;
    private String otherDiseaseName;
}