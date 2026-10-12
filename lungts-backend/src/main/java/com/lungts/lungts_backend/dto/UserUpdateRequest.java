package com.lungts.lungts_backend.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Set;

@Getter
@NoArgsConstructor
public class UserUpdateRequest {

    private String name;

    private Set<String> diseases;

    private String otherDiseaseName;
}