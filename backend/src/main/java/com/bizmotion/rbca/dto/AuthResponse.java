package com.bizmotion.rbca.dto;
import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.Set;
@Getter
@AllArgsConstructor
public class AuthResponse {
    private String      accessToken;
    private String      refreshToken;
    private String      role;
    private Set<String> scopes;
    private String      username;
    private Long        userId;
}