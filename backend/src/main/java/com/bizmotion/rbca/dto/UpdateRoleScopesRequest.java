package com.bizmotion.rbca.dto;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import java.util.List;
@Getter @Setter
public class UpdateRoleScopesRequest {
    @NotNull(message = "Scope ID list is required")
    private List<Long> scopeIds;
}