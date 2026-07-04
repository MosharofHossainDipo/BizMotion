package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
@Getter @Setter
public class CreateScopeRequest {
    @NotBlank(message = "Scope name is required")
    private String scopeName;
    @NotNull(message = "Target role ID is required")
    private Long targetRoleId;
}