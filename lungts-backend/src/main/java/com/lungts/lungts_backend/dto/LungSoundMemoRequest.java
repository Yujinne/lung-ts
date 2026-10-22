
package com.lungts.lungts_backend.dto;

import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LungSoundMemoRequest {

    @Size(max = 1000, message = "메모는 1000자 이내로 작성해주세요.")
    private String memo;
}
