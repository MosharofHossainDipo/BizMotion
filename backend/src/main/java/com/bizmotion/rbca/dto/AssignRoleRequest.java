package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class AssignRoleRequest {
    @NotNull(message = "Role ID is required")
    private Long roleId;
}